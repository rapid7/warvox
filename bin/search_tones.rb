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
require "kissfft"

#
# Script
#

def usage
	$stderr.puts "#{$0} [audio.raw] <min-power>"
	exit
end

raw = WarVOX::Audio::Raw.from_file(ARGV.shift || usage)
min = (ARGV.shift || 1).to_f
res = KissFFT.fftr(4096, 8000, 1, raw.samples)

tones = {}
res.each do |x|
	mf = 0
	mp = 0
	x.each do |o|
		if(o[1] > mp)
			mp = o[1]
			mf = o[0]
		end
	end
	if(mp > min)
		tones[mf.to_i] ||= []
		tones[mf.to_i] <<  [mf, mp]
	end
	# puts "#{mf.to_i}hz @ #{mp.to_i}"
end

tones.keys.sort.each do |t|
	puts "#{t}hz"
	tones[t].each do |x|
		puts "\t#{x[0]}hz @ #{x[1]}"
	end
end




