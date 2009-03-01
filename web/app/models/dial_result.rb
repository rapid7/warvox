class DialResult < ActiveRecord::Base
	belongs_to :provider
	belongs_to :dial_job
end
