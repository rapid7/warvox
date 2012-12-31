class Job < ActiveRecord::Base
	has_many :calls
	belongs_to :project
end
