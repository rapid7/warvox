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

cnt = 0
raw = WarVOX::Audio::Raw.from_file(ARGV.shift || usage)
raw.samples.each do |val|
	puts "#{cnt} #{val}"
	cnt += 1
end
