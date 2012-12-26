class Provider < ActiveRecord::Base
	has_many :dial_results

	validates_presence_of :name, :host, :port, :user, :pass, :lines
	validates_numericality_of :port, :less_than => 65536, :greater_than => 0
	validates_numericality_of :lines, :less_than => 255, :greater_than => 0

	attr_accessible :name, :host, :port, :user, :pass, :lines
end
