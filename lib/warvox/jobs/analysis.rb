module WarVOX
module Jobs
class Analysis < Base 

	require 'fileutils'
	
	@@kissfft_loaded = false
	begin
		require 'kissfft'
		@@kissfft_loaded = true
	rescue ::LoadError
	end
	
	def type
		'analysis'
	end
	
	def initialize(job_id)
		@name = job_id
		if(not @@kissfft_loaded)
			raise RuntimeError, "The KissFFT module is not availabale, analysis failed"
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
		model.save
		
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
		todo.each do |r|
			next if r.processed
			next if not r.completed
			next if r.busy
			next if not r.rawfile
			next if not File.exist?(r.rawfile)

			bname = r.rawfile.gsub(/\..*/, '')
			num   = r.number
			
			#
			# Create the signature database
			# 
			
			raw  = WarVOX::Audio::Raw.from_file(r.rawfile)
			flow = raw.to_flow
			fd   = File.new("#{bname}.sig", "wb")
			fd.write flow
			fd.close
			
			# Save the signature data
			r.sig_data = flow
			
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
			
			# Perform a DFT on the samples
			res = KissFFT.fftr(8192, 8000, 1, raw.samples)
			
			# Calculate the peak frequencies for the sample
			maxf = 0
			maxp = 0
			tones = {}
			res.each do |x|
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
			r.peak_freq = maxf
			
			# Calculate average frequency and peaks over time
			avg = {}
			pks = []
			res.each do |slot|
				pks << slot.sort{|a,b| a[1] <=> b[1] }.reverse[0]
				slot.each do |freq|
					avg[ freq[0] ] ||= 0
					avg[ freq[0] ] +=  freq[1]
				end
			end
			
			# Save the peak frequencies over time
			r.peak_freq_data = pks.map{|f| "#{f[0]}-#{f[1]}" }.join(" ")
			
			# Generate the frequency file
			avg.keys.sort.each do |k|
				avg[k] = avg[k] / res.length
				frefile.write("#{k} #{avg[k]}\n")
			end
			frefile.flush

			#
			# XXX: store significant frequencies somewhere (tones)
			#
			
			# Make a guess as to what kind of phone number we found
			line_type = nil
			while(not line_type)

				# Look for modems by detecting 2250hz tones
				f_2250 = 0
				pks.each{|f| f_2250 += 1 if(f[0] > 2240 and f[0] < 2260) }
				if(f_2250 > 2)
					line_type = 'modem'
					break				
				end
				
				# Look for the 1000hz voicemail BEEP
				if(r.peak_freq > 990 and r.peak_freq < 1010)
					line_type = 'voicemail'
					break
				end

				# Most faxes have at least two of the following tones
				f_1625 = f_1660 = f_1825 = f_2100 = false
				pks.each do |f|
					# $stderr.puts "#{r.number} #{f.inspect}"
					f_1625 = true if(f[0] > 1620 and f[0] < 1630)
					f_1660 = true if(f[0] > 1655 and f[0] < 1665)
					f_1825 = true if(f[0] > 1820 and f[0] < 1830)
					f_2100 = true if(f[0] > 2090 and f[0] < 2110)										
				end
				if([ f_1625, f_1660, f_1825, f_2100 ].grep(true).length >= 2)
					line_type = 'fax'
					break
				end			

				# Dial tone detection
				f_440 = false
				f_350 = false
				pks.each do |f|
					f_440 = true if(f[0] > 435 and f[0] < 445)
					f_345 = true if(f[0] > 345 and f[0] < 355)
				end
				if(f_440 and f_350)
					line_type = 'dialtone'
					break
				end
				
				# Detect humans based on long pauses
				
				# Default to voice
				line_type = 'voice'
			end

			# Save the guessed line type
			r.line_type = line_type

			# Plot samples to a graph
			plotter = Tempfile.new("gnuplot")

			plotter.puts("set ylabel \"Signal\"")
			plotter.puts("set xlabel \"Seconds\"")
			plotter.puts("set terminal png medium size 640,480 transparent")
			plotter.puts("set output \"#{bname}_big.png\"")
			plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with lines")
			plotter.puts("set output \"#{bname}_big_dots.png\"")
			plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with dots")

			plotter.puts("set terminal png medium size 640,480 transparent")
			plotter.puts("set ylabel \"Power\"")
			plotter.puts("set xlabel \"Frequency\"")
			plotter.puts("set output \"#{bname}_freq_big.png\"")
			plotter.puts("plot \"#{frefile.path}\" using 1:2 title \"#{num} - Peak #{maxf.round}hz\" with lines")

			plotter.puts("set ylabel \"Signal\"")
			plotter.puts("set xlabel \"Seconds\"")
			plotter.puts("set terminal png small size 160,120 transparent")
			plotter.puts("set format x ''")
			plotter.puts("set format y ''")	
			plotter.puts("set output \"#{bname}.png\"")
			plotter.puts("plot \"#{datfile.path}\" using 1:2 notitle with lines")

			plotter.puts("set ylabel \"Power\"")
			plotter.puts("set xlabel \"Frequency\"")					
			plotter.puts("set terminal png small size 160,120 transparent")
			plotter.puts("set format x ''")
			plotter.puts("set format y ''")	
			plotter.puts("set output \"#{bname}_freq.png\"")
			plotter.puts("plot \"#{frefile.path}\" using 1:2 notitle with lines")						
			plotter.flush

			system("gnuplot #{plotter.path}")
			File.unlink(plotter.path)
			File.unlink(datfile.path)
			plotter.close
			datfile.close

			# Generate a MP3 audio file
			system("sox -s -w -r 8000 -t raw -c 1 #{rawfile.path} #{bname}.wav")
			system("lame #{bname}.wav #{bname}.mp3 >/dev/null 2>&1")
			File.unlink("#{bname}.wav")
			File.unlink(rawfile.path)
			rawfile.close
			
			# XXX: Dump the frequencies
			
			# Save the changes
			r.processed = true
			r.processed_at = Time.now
			r.save
		end
	end

end
end
end
