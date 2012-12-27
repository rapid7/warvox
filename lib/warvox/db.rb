module WarVOX
class DB < ::Hash
		
	VERSION = '1.0'
	
	class Error < ::RuntimeError
	end
	
	attr_accessor :path, :threshold, :version

	def initialize(path, threshold=800)
		self.path      = path
		self.threshold = threshold
		self.version   = VERSION
		import(path) if path
	end
	
	def import(path)
		File.open(path, "r") do |fd|
			fd.each_line do |line|
				line.strip!
				next if line.empty?
				bits = line.split(/\s+/)
				name = bits.shift
			
				# Remove leading silence
				bits.shift if bits[0][0,1] == "L"
				
				next if bits.empty?

				self[name] = []
				bits.each do |d|
					s,l,a = d.split(',')
					next if l.to_i < self.threshold
					self[name] << [s, l.to_i, a.to_i]
				end
			end
		end	
	end
	
	#
	# Utility methods
	#
	
	# Find a signature within a sample
	def find_match(pat, sam, opts={})
	
		fuzz    = opts[:fuzz]    || 100
		min_sig = opts[:min_sig] || 2
		
		idx     = 0
		fnd     = nil
		mat     = nil
		r       = 0

		while(idx < pat.length-min_sig)
			sig  = pat[idx,pat.length]
			idx2 = 0

			while (idx2 < sam.length)
				c = 0 
				0.upto(sig.length-1) do |si|
					break if not sam[idx2+si]
					break if not ( 
						sig[si][0] == sam[idx2+si][0] and
						sam[idx2 + si][1] > sig[si][1]-fuzz and
						sam[idx2 + si][1] < sig[si][1]+fuzz
					)
					c += 1
				end

				if (c > r)
					r = c
					fnd = sig[0, r]
					mat = sam[idx2, r]
				end	
				idx2 += 1
			end
			idx += 1
		end
		
		# Return the results
		[fnd, mat, r]
	end
	
	# Find the largest pattern shared between two samples
	def find_sig(num1, num2, opts={})
		
		fuzz  = opts[:fuzz] || 100
		info1 = self[num1]
		info2 = self[num2]
		
		# Make sure both samples exist in the database
		if ( not (info1 and info2 and not (info1.empty? or info2.empty?) ) )
			raise Error, "The database must contain both numbers"
		end

		# Remove the silence prefix from both samples
		info1.shift if info1[0][0] == "L"
		info2.shift if info2[0][0] == "L"
		
		fnd,mat,r = find_match(info1, info2, { :fuzz => fuzz })
		
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
	
	def is_carrier?(num)
		data = self[num]
		raise Error, "The specified number does not exist: #{num}" if not data
		tone = []
		
		min_len = 10000
		
		data.each do |rec|
			next if rec[0] != "H"
			next if rec[1] < min_len
			tone << rec
		end
		
		(tone.empty? or (data.length > 5 and tone.length == 1)) ? false : tone
	end

	def find_carriers
		carriers = {}
		self.keys.sort.each do |num|
			begin
				res = is_carrier?(num)
				next if not res
				carriers[num] = res
			rescue Error
			end
		end
		carriers
	end

end
end
