##
#  top level include file for warvox libaries
##

# Load components
require 'warvox/config'
require 'warvox/jobs'
require 'warvox/phone'
require 'warvox/audio'
require 'logger'

# Global configuration
module WarVOX
	VERSION = '2.0.0-dev'
	Base = File.expand_path(File.join(File.dirname(__FILE__), '..'))
	Conf = File.expand_path(File.join(Base, 'config', 'warvox.conf'))
	Log  = Logger.new( WarVOX::Config.log_file )
	Log.level = WarVOX::Config.log_level

end
