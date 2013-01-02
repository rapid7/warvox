class CallMedium < ActiveRecord::Base
	belongs_to :call
	belongs_to :project
end
