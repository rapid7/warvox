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
	$stderr.puts "#{$0} [/path/to/raw/data/] <destination dir> "
	exit
end

require "fileutils"
require "tempfile"

src = ARGV.shift || usage
dst = ARGV.shift || File.join(File.dirname(base), '..', 'data', 'media')

FileUtils.mkdir_p(dst)

calls = []
dir = Dir.new(src)
dir.entries.sort.each do |ent|

	path = File.join(src, ent)
	next if ent !~ /(.*)\.raw\.gz$/m
	num = $1

	next if File.exist?(File.join(dst, num + ".mp3"))

	puts "Processing #{num}..."

	# Decompress the audio file
	rawfile = Tempfile.new("rawfile")
	datfile = Tempfile.new("datfile")

	cnt = 0
	raw = WarVOX::Audio::Raw.from_file(path)
	rawfile.write(raw.samples.pack('v*'))
	datfile.write(raw.samples.map{|val| cnt +=1; "#{cnt} #{val}"}.join("\n"))
	rawfile.flush
	datfile.flush

	# Plot samples to a graph
	plotter = Tempfile.new("gnuplot")
	
	plotter.puts("set ylabel \"Signal\"")
	plotter.puts("set xlabel \"Time\"")
	
	plotter.puts("set terminal png medium size 640,480 transparent")
	plotter.puts("set output \"#{dst}/#{num}_big.png\"")
	plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with lines")

	plotter.puts("set output \"#{dst}/#{num}_big_dots.png\"")
	plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with dots")
			
	plotter.puts("set terminal png small size 160,120 transparent")
	plotter.puts("set format x ''")
	plotter.puts("set format y ''")	
	plotter.puts("set output \"#{dst}/#{num}.png\"")
	plotter.puts("plot \"#{datfile.path}\" using 1:2 title \"#{num}\" with lines")
	plotter.flush
	
	system("gnuplot #{plotter.path}")
	File.unlink(plotter.path)
	File.unlink(datfile.path)
	plotter.close
	datfile.close
		
	# Generate a MP3 audio file
	system("sox -s -2 -r 8000 -t raw -c 1 #{rawfile.path} #{dst}/#{num}.wav")
	system("lame #{dst}/#{num}.wav #{dst}/#{num}.mp3 >/dev/null 2>&1")
	File.unlink("#{dst}/#{num}.wav")
	File.unlink(rawfile.path)
	rawfile.close
end
