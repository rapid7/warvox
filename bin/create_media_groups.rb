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
require 'fileutils'

#
# Script
#

def usage
	$stderr.puts "#{$0} [groups_file] [media_source] [destination]"
	exit
end


group = ARGV.shift || usage()
src   = ARGV.shift || usage()
dst   = ARGV.shift || usage()


File.readlines(group).each do |line|
	line.strip!
	line.gsub!(/\-\d+/, '')
	bits = line.split(/\s+/)

	
	gdir = File.join(dst, bits[0])
	FileUtils.mkdir_p(gdir)
	puts "Processing #{bits[0]}..."
	bits.each do |num|
		system("cp #{src}/#{num}.* #{gdir}")
	end
	
end



FileUtils.mkdir_p(dst)
