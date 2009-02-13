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
	$stderr.puts "#{$0} [warvox.db] [num1] [num2] <fuzz-factor> <db-threshold>"
	exit
end

inp     = ARGV.shift() || usage
num1    = ARGV.shift() || usage
num2    = ARGV.shift() || usage
fuzz    = (ARGV.shift() || 100).to_i
thresh  = (ARGV.shift() || 800).to_i

info1 = []
info2 = []

wdb   = WarVOX::DB.new(inp, thresh)
puts wdb.find_sig(num1, num2, { :fuzz => fuzz }).inspect
