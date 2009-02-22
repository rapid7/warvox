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
res = KissFFT.fftr(8192, 8000, 1, raw.samples)

tones = {}
res.each do |x|
	rank = x.sort{|a,b| a[1].to_i <=> b[1].to_i }.reverse
	rank[0..10].each do |t|
		f = t[0].round
		p = t[1].round
		next if f == 0
		next if p < min
		tones[ f ] ||= []
		tones[ f ] << t
	end
end


tones.keys.sort.each do |t|
	next if tones[t].length < 2
	puts "#{t}hz"
	tones[t].each do |x|
		puts "\t#{x[0]}hz @ #{x[1]}"
	end
end




