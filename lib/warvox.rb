##
#  top level include file for warvox libaries
##

# Load components
require 'warvox/config'
require 'warvox/jobs'
require 'warvox/phone'
require 'warvox/audio'

# Global configuration
module WarVOX
	VERSION = '2.0.0-dev'
	Base = File.expand_path(File.join(File.dirname(__FILE__), '..'))
	Conf = File.expand_path(File.join(Base, 'config', 'warvox.conf'))
	JobManager = WarVOX::JobQueue.new
end
