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

=begin
	8,000 samples per second
	160 samples per block of data
=end

cnt = 0
inp = ARGV.shift || exit
raw = File.read(inp)
raw.unpack("v*").each do |s|
	val = (s > 0x7fff) ? (0x10000 - s) * -1 : s
	puts "#{cnt} #{val}"
	cnt += 1
end

