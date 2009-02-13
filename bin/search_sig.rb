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
sig = ARGV.join(' ')

min_len = 800

# Load the signature from the command line

info1 = []
bits = sig.split(/\s+/)
head = bits.shift
bits.each do |s|
	inf = s.split(",")
	info1 << [inf[0], inf[1].to_i, inf[2].to_i]
end

# Search for matching numbers

fd = File.open(inp, "r")
fd.each_line do |line|
	data = line.strip.split(/\s+/)
	name = data.shift

	# Bump the leading silence off
	data.shift if data[0] =~ /^L/
	
	fnd   = nil
	info2 = []
	data.each do |d|
		s,l,a = d.split(",")
		next if l.to_i < min_len
		info2 << [s, l.to_i, a.to_i]
	end

	fuzz    = 100 #XXX read from sig
	idx2 = 0
	fnd  = nil
	r    = 0

	sig = info1
	
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

	if(fnd and r == sig.length)
		puts "MATCHED: #{name} #{r}"
	end
end
