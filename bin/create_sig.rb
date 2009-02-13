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

inp = ARGV.shift()
num1 = ARGV.shift() || exit
num2 = ARGV.shift() || exit

min_len = 800


info1 = []
info2 = []

fd = File.open(inp, "r")
fd.each_line do |line|
	data = line.strip.split(/\s+/)
	name = data.shift
	next if name !~ /#{num1}|#{num2}/
	
	# Bump the leading silence off
	data.shift if data[0] =~ /^L/
	
	data.each do |d|
		s,l,a = d.split(",")
		next if l.to_i < min_len
		plot = [s, l.to_i, a.to_i]
		name =~ /#{num1}/ ? info1 << plot : info2 << plot
	end
	
	break if (info1.length > 0 and info2.length > 0)
end

if (not (info1.length > 0 and info2.length > 0))
	$stderr.puts "error: could not find both numbers in the database"
	exit
end


min_sig = 2
fuzz    = 100
idx     = 0
fnd     = nil
r       = 0

while(idx < info1.length-min_sig)
	sig  = info1[idx,info1.length]
	idx2 = 0

	while (idx2 < info2.length)
		c = 0 
		0.upto(sig.length-1) do |si|
			break if not info2[idx2+si]
			break if not ( 
				sig[si][0] == info2[idx2+si][0] and
				info2[idx2 + si][1] > sig[si][1]-fuzz and
				info2[idx2 + si][1] < sig[si][1]+fuzz
			)
			c += 1
		end
		
		if (c > r)
			r = c
			fnd = sig[0, r]
		end	
		idx2 += 1
	end
	idx += 1
end




version = "1.0"

if(fnd)
	sig = "V=#{version},F=#{fuzz},S1=#{num1},S2=#{num2},L=#{r} "
	fnd.each do |i|
		sig << i.join(",") + " "
	end
	puts sig
end
