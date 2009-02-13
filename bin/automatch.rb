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

threads = 2 
inp     = ARGV.shift || usage
thresh  = (ARGV.shift() || 800).to_i
wdb     = WarVOX::DB.new(inp, thresh)

# Scrub the carriers out of the pool first
car = wdb.find_carriers
car.keys.each do |k|
	wdb.delete(k)
end

groups = 
{
	"carriers" => car.keys
}

oset = wdb.keys.sort
iset = oset.dup



while(not oset.empty?)

	k = oset.shift
	
	found = []
	best  = nil
	next if not iset.include?(k)
	
	iset.each do |n|
		next if k == n
		
		begin
			res = wdb.find_sig(k,n)
		rescue ::WarVOX::DB::Error
		end
		
		next if not res
		next if res[:len] < 5
		found << res
	end
	
	next if found.empty?
	
	groups[k] = [ ]
	found.each do |f|
		groups[k] << [ f[:num2], f[:len] ]
	end

	$stdout.puts "#{k} " + groups[k].map{|x| "#{x[0]}-#{x[1]}" }.join(" ")
	$stdout.flush
	
	groups[k].unshift(k)
end

