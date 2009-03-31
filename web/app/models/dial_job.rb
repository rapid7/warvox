class DialJob < ActiveRecord::Base
	has_many :dial_results

	validates_presence_of :range, :lines, :seconds
	validates_numericality_of :lines, :less_than => 256, :greater_than => 0
	validates_numericality_of :seconds, :less_than => 301, :greater_than => 0

	def validate
		if(range.gsub(/[^0-9X,\n]/, '').empty?)
			errors.add(:range, "The range must be at least 1 character long and made up of 0-9 and X as the mask.")
		end
		
		if(range.scan(/X/).length > 5)
			errors.add(:range, "The range must contain no more than 5 mask digits.")
		end
		
		if(cid_mask != "SELF" and cid_mask.gsub(/[^0-9X]/, '').empty?)
			errors.add(:range, "The Caller ID must be at least 1 character long and made up of 0-9 and X as the mask.")
		end
			
		if(cid_mask != "SELF" and cid_mask.scan(/X/).length > 5)
			errors.add(:range, "The Caller ID must contain no more than 5 mask digits.")
		end		
	end
end
