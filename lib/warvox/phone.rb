module WarVOX
class Phone

	# Convert 123456XXXX to an array of expanded numbers
	def self.crack_mask(masks)
		res = {}
		masks.each do |mask|
			mask = mask.strip
			incdigits = 0
			mask.each_char do |c|
				incdigits += 1 if c =~ /^[X#]$/i
			end
	
			max = (10**incdigits)-1
	
			(0..max).each do |num|
				number = mask.dup # copy the mask
				numstr = sprintf("%0#{incdigits}d", num) # stringify our incrementing number
				j = 0 # index for numstr
				for i in 0..number.length-1 do # step through the number (mask)
					if number[i].chr =~ /^[X#]$/i
						number[i] = numstr[j] # replaced masked indexes with digits from incrementing number
						j += 1
					end
				end
				res[number] = {}
			end
	
		end
                res.each { |key, value|
                        print "DEBUG: key=",key," -> ",value,"\n"
                }

		return res.keys.sort
	end

end
end
