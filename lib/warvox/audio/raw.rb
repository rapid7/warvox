module WarVOX
module Audio
class Raw

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

end
end
end
