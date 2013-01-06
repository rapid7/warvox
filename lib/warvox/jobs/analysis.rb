module WarVOX
module Jobs
class Analysis < Base

	require 'fileutils'
	require 'tempfile'
	require 'open3'

	require 'kissfft'

	class Classifier

		class Completed < RuntimeError
		end

		attr_accessor :line_type
		attr_accessor :signatures
		attr_accessor :data

		def initialize
			@signatures = []
			@data = {}
		end

		def proc(str)
			begin
				eval(str)
			rescue Completed
			end
		end
	end

	def type
		'analysis'
	end

	def initialize(job_id, conf)
		@job_id = job_id
		@conf   = conf
		@tasks  = []
		@calls  = []
	end

	def stop
		@calls = []
		@tasks.each do |t|
			t.kill rescue nil
		end
		@tasks = []
	end

	def start

		@calls = []

		query = nil

		::ActiveRecord::Base.connection_pool.with_connection {

		begin

		job = Job.find(@job_id)
		if not job
			raise RuntimeError, "The parent job no longer exists"
		end

		case @conf[:scope]
		when 'job'
			if @conf[:force]
				query = {:job_id => @conf[:target_id], :answered => true, :busy => false}
			else
				query = {:job_id => @conf[:target_id], :answered => true, :busy => false, :analysis_started_at => nil}
			end
		when 'project'
			if @conf[:force]
				query = {:project_id => @conf[:target_id], :answered => true, :busy => false}
			else
				query = {:project_id => @conf[:target_id], :answered => true, :busy => false, :analysis_started_at => nil}
			end
		when 'global'
			if @conf[:force]
				query = {:answered => true, :busy => false}
			else
				query = {:answered => true, :busy => false, :analysis_started_at => nil}
			end
		end



		# Build a list of call IDs, as find_each() gets confused if the DB changes mid-iteration
		calls = Call.where(query).map{|c| c.id }

		@total_calls     = calls.length
		@completed_calls = 0

		max_threads = WarVOX::Config.analysis_threads
		last_update = Time.now

		while(calls.length > 0)
			if @tasks.length < max_threads
				@tasks << Thread.new(calls.shift, job.id) { |c,j| ::ActiveRecord::Base.connection_pool.with_connection { run_analyze_call(c,j) }}
			else
				clear_stale_tasks

				# Update progress every 10 seconds or so
				if Time.now.to_f - last_update.to_f > 10
					update_progress((@completed_calls / @total_calls.to_f) * 100)
					last_update = Time.now
				end

				clear_zombies
			end
		end

		@tasks.map {|t| t.join }
		clear_stale_tasks
		clear_zombies

		rescue ::Exception => e
			WarVOX::Log.error("Exception: #{e.class} #{e} #{e.backtrace}")
		end

		}
	end

	def clear_stale_tasks
		@tasks = @tasks.select{ |x| x.status }
		IO.select(nil, nil, nil, 0.25)
	end

	def update_progress(pct)
		::ActiveRecord::Base.connection_pool.with_connection {
			Job.update_all({ :progress => pct }, { :id => @job_id })
		}
	end

	def run_analyze_call(cid, jid)

		dr = Call.find(cid)
		dr.analysis_started_at = Time.now.utc
		dr.analysis_job_id = jid
		dr.save

		WarVOX::Log.debug("Worker processing audio for #{dr.number}...")

		bin = File.join(WarVOX::Base, 'bin', 'analyze_result.rb')
		tmp = Tempfile.new("Analysis")
		begin

		mr = dr.media
		::File.open(tmp.path, "wb") do |fd|
			fd.write(mr.audio)
		end

		pfd = IO.popen("#{bin} '#{tmp.path}' '#{ dr.number.gsub(/[^0-9a-zA-Z\-\+]+/, '') }'")
		out = Marshal.load(pfd.read) rescue nil
		pfd.close

		return if not out

		mf = dr.media_fields
		out.each_key do |k|
			if mf.include?(k.to_s)
				mr[k] = out[k]
			else
				dr[k] = out[k]
			end
		end

		dr.analysis_completed_at = Time.now.utc

		rescue ::Interrupt
		ensure
			tmp.close
			tmp.unlink
		end

		mr.save
		dr.save

		@completed_calls += 1
	end

	# Takes the raw file path as an argument, returns a hash
	def self.analyze_call(input, num=nil)

		return if not input
		return if not File.exist?(input)

		bname   = File.expand_path(File.dirname(input))
		num   ||= File.basename(input)
		res     = {}

		#
		# Create the signature database
		#
		raw  = WarVOX::Audio::Raw.from_file(input)
		fft  = KissFFT.fftr(8192, 8000, 1, raw.samples) || []

		freq = raw.to_freq_sig_arr()

		# Save the signature data
		res[:fprint] = freq

		#
		# Create a raw decompressed file
		#

		# Decompress the audio file
		rawfile = Tempfile.new("rawfile")
		datfile = Tempfile.new("datfile")

		# Data files for audio processing and signal graph
		cnt = 0
		rawfile.write(raw.samples.pack('v*'))
		datfile.write(raw.samples.map{|val| cnt +=1; "#{cnt/8000.0} #{val}"}.join("\n"))
		rawfile.flush
		datfile.flush

		# Data files for spectrum plotting
		frefile = Tempfile.new("frefile")

		# Calculate the peak frequencies for the sample
		maxf = 0
		maxp = 0
		tones = {}
		fft.each do |x|
			rank = x.sort{|a,b| a[1].to_i <=> b[1].to_i }.reverse
			rank[0..10].each do |t|
				f = t[0].round
				p = t[1].round
				next if f == 0
				next if p < 1
				tones[ f ] ||= []
				tones[ f ] << t
				if(t[1] > maxp)
					maxf = t[0]
					maxp = t[1]
				end
			end
		end

		# Save the peak frequency
		res[:peak_freq] = maxf

		# Calculate average frequency and peaks over time
		avg = {}
		pks = []
		pkz = []
		fft.each do |slot|
			pks << slot.sort{|a,b| a[1] <=> b[1] }.reverse[0]
			pkz << slot.sort{|a,b| a[1] <=> b[1] }.reverse[0..9]
			slot.each do |f|
				avg[ f[0] ] ||= 0
				avg[ f[0] ] +=  f[1]
			end
		end

		# Save the peak frequencies over time
		res[:peak_freq_data] = pks.map{|f| "#{f[0]}-#{f[1]}" }.join(" ")

		# Generate the frequency file
		avg.keys.sort.each do |k|
			avg[k] = avg[k] / fft.length
			frefile.write("#{k} #{avg[k]}\n")
		end
		frefile.flush

		# Count significant frequencies across the sample
		fcnt = {}
		0.step(4000, 5) {|f| fcnt[f] = 0 }
		pkz.each do |fb|
			fb.each do |f|
				fdx = ((f[0] / 5.0).round * 5.0).to_i
				fcnt[fdx]  += 0.1
			end
		end

		#
		# Classifier processing
		#

		sproc = Classifier.new
		sproc.data =
		{
			:raw  => raw,
			:freq => freq,
			:fcnt => fcnt,
			:fft  => fft,
			:pks  => pks,
			:pkz  => pkz,
			:maxf => maxf,
			:maxp => maxp
		}

		WarVOX::Config.classifiers_load.each do |sigfile|
			begin
				str = File.read(sigfile, File.size(sigfile))
				sproc.proc(str)
			rescue ::Exception => e
				$stderr.puts "DEBUG: Caught exception in #{sigfile}: #{e} #{e.backtrace}"
			end
			break if sproc.line_type
		end

		# Save the guessed line type
		res[:line_type] = sproc.line_type

		png_big       = Tempfile.new("big")
		png_big_dots  = Tempfile.new("bigdots")
		png_big_freq  = Tempfile.new("bigfreq")
		png_sig       = Tempfile.new("signal")
		png_sig_freq  = Tempfile.new("sigfreq")

		# Plot samples to a graph
		plotter = Tempfile.new("gnuplot")

		plotter.puts("set ylabel \"Signal\"")
		plotter.puts("set xlabel \"Seconds\"")
		plotter.puts("set terminal png medium size 640,480 transparent")
		plotter.puts("set output \"#{png_big.path}\"")
		plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with lines")
		plotter.puts("set output \"#{png_big_dots.path}\"")
		plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with dots")

		plotter.puts("set terminal png medium size 640,480 transparent")
		plotter.puts("set ylabel \"Power\"")
		plotter.puts("set xlabel \"Frequency\"")
		plotter.puts("set output \"#{png_big_freq.path}\"")
		plotter.puts("plot \"#{frefile.path}\" using 1:2 title \"#{num} - Peak #{maxf.round}hz\" with lines")


		plotter.puts("unset border")
		plotter.puts("unset xtics")
		plotter.puts("unset ytics")
		plotter.puts("set ylabel \"\"")
		plotter.puts("set xlabel \"\"")
		plotter.puts("set terminal png small size 80,60 transparent")
		plotter.puts("set format x ''")
		plotter.puts("set format y ''")
		plotter.puts("set output \"#{png_sig.path}\"")
		plotter.puts("set style line 1 lt 1 lw 3 pt 3 linecolor rgb \"gray\"")
		plotter.puts("plot \"#{datfile.path}\" using 1:2 notitle with lines")

		plotter.puts("unset border")
		plotter.puts("unset xtics")
		plotter.puts("unset ytics")
		plotter.puts("set ylabel \"\"")
		plotter.puts("set xlabel \"\"")
		plotter.puts("set terminal png small size 80,60 transparent")
		plotter.puts("set format x ''")
		plotter.puts("set format y ''")
		plotter.puts("set output \"#{png_sig_freq.path}\"")
		plotter.puts("set style line 1 lt 1 lw 3 pt 3 linecolor rgb \"gray\"")
		plotter.puts("plot \"#{frefile.path}\" using 1:2 notitle with lines")
		plotter.flush

		system("#{WarVOX::Config.tool_path('gnuplot')} #{plotter.path}")
		File.unlink(plotter.path)
		File.unlink(datfile.path)
		File.unlink(frefile.path)
		plotter.close
		datfile.close
		frefile.path

		::File.open(png_big.path, 'rb')      { |fd| res[:png_big]      = fd.read }
		::File.open(png_big_dots.path, 'rb') { |fd| res[:png_big_dots] = fd.read }
		::File.open(png_big_freq.path, 'rb') { |fd| res[:png_big_freq] = fd.read }
		::File.open(png_sig.path, 'rb')      { |fd| res[:png_sig]      = fd.read }
		::File.open(png_sig_freq.path, 'rb') { |fd| res[:png_sig_freq] = fd.read }

		[png_big, png_big_dots, png_big_freq, png_sig, png_sig_freq ].map {|x| x.unlink; x.close }

		tmp_wav = Tempfile.new("wav")
		tmp_mp3 = Tempfile.new("mp3")

		# Generate a WAV file from raw linear PCM
		::File.open(tmp_wav.path, "wb") do |fd|
			fd.write(raw.to_wav)
		end

		# Default samples at 8k, bump it to 32k to get better quality
		system("#{WarVOX::Config.tool_path('lame')} -b 32 #{tmp_wav.path} #{tmp_mp3.path} >/dev/null 2>&1")

		File.unlink(rawfile.path)
		rawfile.close

		::File.open(tmp_mp3.path, "rb") { |fd| res[:mp3] = fd.read }

		[tmp_wav, tmp_mp3].map {|x| x.unlink; x.close }

		clear_zombies()

		res
	end
end


end
end
