module WarVOX
module Audio
class Raw
	
	@@kissfft_loaded = false
	begin
		require 'kissfft'
		@@kissfft_loaded = true
	rescue ::LoadError
	end
		
	require 'zlib'

	##
	# RAW AUDIO - 8khz little-endian 16-bit signed
	##

	##
	# Static methods
	## 
	
	def self.from_str(str)
		self.class.new(str)
	end
	
	def self.from_file(path)
		if(not path)
			raise Error, "No audio path specified"
		end
		
		if(path == "-")
			return self.new($stdin.read)
		end
		
		if(not File.readable?(path))
			raise Error, "The specified audio file does not exist"
		end
		
		if(path =~ /\.gz$/)
			return self.new(Zlib::GzipReader.open(path).read)
		end
	
		self.new(File.read(path, File.size(path)))
	end

	##
	# Class methods
	## 
	
	attr_accessor :samples
	
	def initialize(data)
		self.samples = data.unpack('v*').map do |s| 
			(s > 0x7fff) ? (0x10000 - s) * -1 : s
		end
	end
	
	def to_flow(opts={})

		lo_lim = (opts[:lo_lim] || 100).to_i
		lo_min = (opts[:lo_min] || 5).to_i
		hi_min = (opts[:hi_min] || 5).to_i
		lo_cnt = 0		
		hi_cnt = 0

		data = self.samples.map {|c| c.abs}

		#
		# Granular hi/low state change list
		#
		fprint = []
		state  = :lo
		idx    = 0
		buff   = []

		while (idx < data.length)
			case state
			when :lo
				while(idx < data.length and data[idx] <= lo_lim)
					buff << data[idx]
					idx += 1
				end

				# Ignore any sequence that is too small
				fprint << [:lo, buff.length, buff - [0]] if buff.length > lo_min
				state  = :hi
				buff   = []
				next
			when :hi
				while(idx < data.length and data[idx] > lo_lim)
					buff << data[idx]
					idx += 1
				end	

				# Ignore any sequence that is too small
				fprint << [:hi, buff.length, buff] if buff.length > hi_min
				state  = :lo
				buff   = []
				next
			end
		end

		#
		# Merge similar blocks
		#
		final = []
		prev  = fprint[0]
		idx   = 1

		while(idx < fprint.length)

			if(fprint[idx][0] == prev[0])
				prev[1] += fprint[idx][1]
				prev[2] += fprint[idx][2]
			else
				final << prev
				prev  = fprint[idx]
			end

			idx += 1
		end
		final << prev

		#
		# Process results
		# 
		sig = ""

		final.each do |f|
			sum = 0
			f[2].each {|i| sum += i }
			avg = (sum == 0) ? 0 : sum / f[2].length
			sig << "#{f[0].to_s.upcase[0,1]},#{f[1]},#{avg} "
		end
		
		# Return the results
		return sig
	end

	def to_freq(opts={})

		if(not @@kissfft_loaded)
			raise RuntimeError, "The KissFFT module is not availabale, raw.to_freq() failed"
		end	
		
		freq_cnt = opts[:frequency_count] || 20
		
		# Perform a DFT on the samples
		ffts = KissFFT.fftr(8192, 8000, 1, self.samples)

		self.class.fft_to_freq_sig(ffts, freq_cnt)
	end
	
	def self.fft_to_freq_sig(ffts, freq_cnt)
		sig = []
		ffts.each do |s|
			res = []
			maxp = 0
			maxf = 0
			s.each do |f|
				if( f[1] > maxp )
					maxf,maxp = f
				end
				
				if(maxf > 0 and f[1] < maxp and (maxf + 4.5 < f[0]))
					res << [maxf, maxp]
					maxf,maxp = [0,0]
				end
			end
			
			sig << res.sort{ |a,b|                              # sort by signal strength
				a[1] <=> b[1] 
			}.reverse[0,freq_cnt].sort { |a,b|                 # take the top 20 and sort by frequency
				a[0] <=> b[0]                                   
			}.map {|a| [a[0].round, a[1].round ] }              # round to whole numbers
		end
		
		sig	
	end
	
	# Find pattern inside of sample
	def self.compare_freq_sig(pat, zam, opts)	
		
		fuzz_f = opts[:fuzz_f] || 7
		fuzz_p = opts[:fuzz_p] || 10
		final  = []
		
		0.upto(zam.length - 1) do |si|
			res = []		
			sam = zam[si, zam.length]
	
			0.upto(pat.length - 1) do |pi|
				diff = []
				next if not pat[pi]
				next if pat[pi].length == 0
				pat[pi].each do |x|
					next if not sam[pi]
					next if sam[pi].length == 0
					sam[pi].each do |y|
						if(
							(x[0] - fuzz_f) < y[0] and
							(x[0] + fuzz_f) > y[0] and
							(x[1] - fuzz_p) < y[1] and
							(x[1] + fuzz_p) > y[1]
						)
							diff << x
							break
						end
					end
				end
				res << diff
			end
			next if res.length == 0

			prev = 0
			rsum = 0
			ridx = 0
			res.each_index do |xi|
				len = res[xi].length
				if(xi == 0)
					rsum += (len < 2) ? -40 : +20
				else
					rsum += 20 if(prev > 11 and len > 11)
					rsum += len
				end
				prev = len
			end
			
			final << [ (rsum / res.length.to_f), res.map {|x| x.length}]
		end
		
		final
	end

end
end
end
