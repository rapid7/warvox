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
	$stderr.puts "#{$0} [warvox.db] <db-threshold> <fuzz>"
	exit
end

threads = 2 
inp     = ARGV.shift || usage
thresh  = (ARGV.shift() || 800).to_i
fuzz    = (ARGV.shift() || 100).to_i
wdb     = WarVOX::DB.new(inp, thresh)

# Scrub the carriers out of the pool first
car = wdb.find_carriers
car.keys.each do |k|
	wdb.delete(k)
end

groups = 
{
	"carriers" => car.keys,
	"unique"   => []
}

oset = wdb.keys.sort
iset = oset.dup


$stdout.puts car.keys.map{|x| "#{x}-100" }.join(" ") 
$stdout.flush
	
while(not oset.empty?)

	s = Time.now
	k = oset.shift
	
	found = {}
	next if not iset.include?(k)
	
	iset.each do |n|
		next if k == n
		
		begin
			res = wdb.find_sig(k,n,{ :fuzz => fuzz })
		rescue ::WarVOX::DB::Error
		end
		
		next if not res
		next if res[:len] < 5
		if(not found[n] or found[n][:len] < res[:len])
			found[n] = res
		end
	end

	if(found.empty?)
		next
	end
	
	groups[k] = [ [k, 0] ]
	found.keys.sort.each do |n|
		groups[k] <<  [n, found[n][:len]]
	end

	$stdout.puts groups[k].map{|x| "#{x[0]}-#{x[1]}" }.join(" ") 
	$stdout.flush
	
	groups[k].unshift(k)

	# Remove matches from the search listing
	iset.delete(k)
	found.keys.each do |k|
		iset.delete(k)
	end
end
iset.each do |k|
	puts "#{k}-0"
end
