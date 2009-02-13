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
	$stderr.puts "#{$0} [warvox.db] <db-threshold>"
	exit
end

inp     = ARGV.shift || usage
thresh  = (ARGV.shift() || 800).to_i
wdb     = WarVOX::DB.new(inp, thresh)
res     = wdb.find_carriers
res.keys.sort.each do |k|
	puts "#{k}\t" + res[k].map{|x| sprintf("%d@%d",x[1],x[2]) }.join(", ")
end
