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

#
# Parameters
#
lo_lim = 100
lo_min = 5
lo_cnt = 0
hi_min = 5
hi_cnt = 0

#
# Input
#
cnt = 0
inp = ARGV.shift || exit
raw = File.read(inp)
data = raw.unpack("s*").map {|c| c.abs}

#
# Granular hi/low state change list
#
fprint = []
state  = :lo
idx    = 0
buff   = []

while (idx < data.length)
	case state
	when :lo
		while(idx < data.length and data[idx] <= lo_lim)
			buff << data[idx]
			idx += 1
		end
		
		# Ignore any sequence that is too small
		fprint << [:lo, buff.length, buff - [0]] if buff.length > lo_min
		state  = :hi
		buff   = []
		next
	when :hi
		while(idx < data.length and data[idx] > lo_lim)
			buff << data[idx]
			idx += 1
		end	
		
		# Ignore any sequence that is too small
		fprint << [:hi, buff.length, buff] if buff.length > hi_min
		state  = :lo
		buff   = []
		next
	end
end


#
# Merge similar blocks
#
final = []
prev  = fprint[0]
idx   = 1

while(idx < fprint.length)
	
	if(fprint[idx][0] == prev[0])
		prev[1] += fprint[idx][1]
		prev[2] += fprint[idx][2]
	else
		final << prev
		prev  = fprint[idx]
	end
	
	idx += 1
end
final << prev


#
# Process results
# 
sig = "#{inp} "

final.each do |f|
	sum = 0
	f[2].each {|i| sum += i }
	avg = (sum == 0) ? 0 : sum / f[2].length
	sig << "#{f[0].to_s.upcase[0,1]},#{f[1]},#{avg} "
end

puts sig
