module WarVOX
class DB
		
	VERSION = '1.0'
	
	class Error < ::RuntimeError
	end
	
	attr_accessor :path, :nums, :threshold, :version

	def initialize(path, threshold=800)
		self.path      = path
		self.threshold = threshold
		self.nums      = {}
		self.version   = VERSION
		
		File.open(path, "r") do |fd|
			fd.each_line do |line|
				line.strip!
				next if line.empty?
				bits = line.split(/\s+/)
				name = bits.shift

				self.nums[name] = []
				bits.each do |d|
					s,l,a = d.split(',')
					next if l.to_i < self.threshold
					self.nums[name] << [s, l.to_i, a.to_i]
				end
			end
		end
	end
	
	def [](num)
		self.nums[num]
	end
	
	def []=(num,val)
		self.nums[num] = val
	end
	
	#
	# Utility methods
	#
	
	def find_sig(num1, num2, opts={})
		
		fuzz  = opts[:fuzz] || 100
		info1 = self[num1]
		info2 = self[num2]
		
		# Make sure both samples exist in the database
		if ( not (info1 and info2 and not (info1.empty? or info2.empty?) ) )
			raise Error, "The database must contain both numbers"
		end
		
		min_sig = 2
		idx     = 0
		fnd     = nil
		mat     = nil
		r       = 0

		while(idx < info1.length-min_sig)
			sig  = info1[idx,info1.length]
			idx2 = 0

			while (idx2 < info2.length)
				c = 0 
				0.upto(sig.length-1) do |si|
					break if not info2[idx2+si]
					break if not ( 
						sig[si][0] == info2[idx2+si][0] and
						info2[idx2 + si][1] > sig[si][1]-fuzz and
						info2[idx2 + si][1] < sig[si][1]+fuzz
					)
					c += 1
				end

				if (c > r)
					r = c
					fnd = sig[0, r]
					mat = info2[idx2, r]
				end	
				idx2 += 1
			end
			idx += 1
		end
		
		return nil if not fnd
		
		sig = []
		fnd.each_index do |i|	
			sig << 
			[
				(fnd[i][0]),
				(fnd[i][1] + mat[i][1] / 2.0).to_i,
				(fnd[i][2] + mat[i][2] / 2.0).to_i
			]
		end
		
		{
			:version    => self.version,
			:fuzz       => fuzz,
			:threshold  => self.threshold,
			:num1       => num1,
			:num2       => num2,
			:len        => r,
			:sig        => sig
		}
	end

end
end
