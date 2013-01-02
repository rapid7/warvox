class Project < ActiveRecord::Base


	validates :name, :uniqueness => true
	validates_presence_of :name

	attr_accessible :name, :description, :included, :excluded

	# This is optimized for fast project deletion, even with thousands of calls/jobs/lines
	has_many :lines, :dependent => :delete_all
	has_many :line_attributes, :dependent => :delete_all
	has_many :calls, :dependent => :delete_all
	has_many :call_media, :dependent => :delete_all
	has_many :jobs, :dependent => :delete_all
end
