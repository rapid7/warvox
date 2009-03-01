class DialJob < ActiveRecord::Base
	has_many :dial_results

	validates_presence_of :range, :lines, :seconds
	validates_numericality_of :lines, :less_than => 256, :greater_than => 0
	validates_numericality_of :seconds, :less_than => 301, :greater_than => 0

	def validate
		if(range.gsub(/[^0-9X]/, '').length != 10)
			errors.add(:range, "The range must be exactly 10 characters long and made up of 0-9 and X as the mask.")
		end
	end
end
