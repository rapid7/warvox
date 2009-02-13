#!/usr/bin/env ruby
###################

#
# Load the library path
# 
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end
$:.unshift(File.join(File.expand_path(File.dirname(base)), '..', 'lib'))
require 'warvox'

#
# Script
#

def usage
	$stderr.puts "#{$0} [audio.raw]"
	exit
end

raw = WarVOX::Audio::Raw.from_file(ARGV.shift || usage)
puts raw.to_flow
