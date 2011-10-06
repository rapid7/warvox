module WarVOX
module Jobs
class Analysis < Base

	require 'fileutils'
	require 'tempfile'
	require 'yaml'
	require 'open3'

	@@kissfft_loaded = false
	begin
		require 'kissfft'
		@@kissfft_loaded = true
	rescue ::LoadError
	end

	class SignalProcessor

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

	def initialize(job_id)
		@name = job_id
		if(not @@kissfft_loaded)
			raise RuntimeError, "The KissFFT module is not available, analysis failed"
		end
	end

	def get_job
		::DialJob.find(@name)
	end

	def start
		@status = 'active'

		begin
		start_processing()

		model = get_job
		model.processed = true
		db_save(model)

		stop()

		rescue ::Exception => e
			$stderr.puts "Exception in the job queue: #{e.class} #{e} #{e.backtrace}"
		end
	end

	def stop
		@status = 'completed'
	end

	def start_processing
		todo = ::DialResult.find_all_by_dial_job_id(@name)
		jobs = []
		todo.each do |r|
			next if r.processed
			next if not r.completed
			next if r.busy
			jobs << r
		end

		max_threads = WarVOX::Config.analysis_threads

		while(not jobs.empty?)
			threads = []
			output  = []
			1.upto(max_threads) do
				j = jobs.shift || break
				output  << j
				threads << Thread.new { run_analyze_call(j) }
			end

			# Wait for the threads to complete
			threads.each {|t| t.join}

			# Save the results to the database
			output.each  {|r| db_save(r) if r.processed }
		end
	end

	def run_analyze_call(r)
		$stderr.puts "DEBUG: Processing audio for #{r.number}..."



		bin = File.join(WarVOX::Base, 'bin', 'analyze_result.rb')
		tmp = Tempfile.new("Analysis")
		begin

		::File.open(tmp.path, "wb") do |fd|
			fd.write(r.audio)
		end

		pfd = IO.popen("#{bin} '#{tmp.path}'")
		out = YAML.load(pfd.read)
		pfd.close

		return if not out

		out.each_key do |k|
			setter = "#{k.to_s}="
			if(r.respond_to?(setter))
				r.send(setter, out[k])
			end
		end

		r.processed_at = Time.now
		r.processed    = true

		rescue ::Interrupt
		ensure
			tmp.close
			tmp.unlink
		end

		true
	end

	# Takes the raw file path as an argument, returns a hash
	def analyze_call(input)

		return if not input
		return if not File.exist?(input)

		bname = File.expand_path(File.dirname(input))
		num   = File.basename(input)
		res   = {}

		#
		# Create the signature database
		#
		raw  = WarVOX::Audio::Raw.from_file(input)
		fft  = KissFFT.fftr(8192, 8000, 1, raw.samples)

		freq = raw.to_freq_sig_txt()

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
		# Signature processing
		#

		sproc = SignalProcessor.new
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

		WarVOX::Config.signatures_load.each do |sigfile|
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

		# Save any matched signatures
		res[:signatures] = sproc.signatures.map{|s| "#{s[0]}:#{s[1]}:#{s[2]}" }.join("\n")

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

		plotter.puts("set ylabel \"Signal\"")
		plotter.puts("set xlabel \"Seconds\"")
		plotter.puts("set terminal png small size 160,120 transparent")
		plotter.puts("set format x ''")
		plotter.puts("set format y ''")
		plotter.puts("set output \"#{png_sig.path}\"")
		plotter.puts("plot \"#{datfile.path}\" using 1:2 notitle with lines")

		plotter.puts("set ylabel \"Power\"")
		plotter.puts("set xlabel \"Frequency\"")
		plotter.puts("set terminal png small size 160,120 transparent")
		plotter.puts("set format x ''")
		plotter.puts("set format y ''")
		plotter.puts("set output \"#{png_sig_freq.path}\"")
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


		# Detect DTMF and MF tones
		dtmf = ''
		mf   = ''
		pfd = IO.popen("#{WarVOX::Config.tool_path('dtmf2num')} -r 8000 1 16 #{rawfile.path} 2>/dev/null")
		pfd.each_line do |line|
			line = line.strip
			if(line.strip =~ /^- MF numbers:\s+(.*)/)
				next if $1 == 'none'
				mf = $1
			end
			if(line.strip =~ /^- DTMF numbers:\s+(.*)/)
				next if $1 == 'none'
				dtmf = $1
			end
		end
		pfd.close
		res[:dtmf] = dtmf
		res[:mf]   = mf


		tmp_wav = Tempfile.new("wav")
		tmp_mp3 = Tempfile.new("mp3")

		# Generate a WAV file from raw linear PCM
		::File.open(tmp_wav, "wb") do |fd|
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


class CallAnalysis < Analysis

	@@kissfft_loaded = false
	begin
		require 'kissfft'
		@@kissfft_loaded = true
	rescue ::LoadError
	end

	def type
		'call_analysis'
	end

	def initialize(result_id)
		@name = result_id
		if(not @@kissfft_loaded)
			raise RuntimeError, "The KissFFT module is not available, analysis failed"
		end
	end

	def get_job
		::DialResult.find(@name)
	end

	def start
		@status = 'active'

		begin
			start_processing()
			stop()
		rescue ::Exception => e
			$stderr.puts "Exception in the job queue: #{e.class} #{e} #{e.backtrace}"
		end
	end

	def stop
		@status = 'completed'
	end

	def start_processing
		r = get_job()
		return if not r.completed
		return if r.busy
		analyze_call(r)
	end
end

end
end

