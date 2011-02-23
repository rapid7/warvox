##
#  top level include file for warvox libaries
##

# Load components
require 'warvox/config'
require 'warvox/jobs'
require 'warvox/phone'
require 'warvox/audio'
require 'warvox/db'

# Global configuration
module WarVOX
	VERSION = '1.2.0'
	Base = File.expand_path(File.join(File.dirname(__FILE__), '..'))
	Conf = File.expand_path(File.join(Base, 'etc', 'warvox.conf'))
	JobManager = WarVOX::JobQueue.new
end
