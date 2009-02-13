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

names = []
inp = ARGV.shift() || exit
fd  = File.open(inp, "r")
fd.each_line do |line|
	data = line.strip.split(/\s+/)
	if(data.shift =~ /(\d+)/)
		if(data.length < 20)
			puts "[*] Skipping carrier #{$1}..."
			next
		end
		names << $1
	end
end


found = {}

names.each do |n1|
	puts "[*] Searching for matches to #{n1}"
	best = 0
	names.each do |n2|
		next if found[n2]
		data = `ruby t.rb #{inp} #{n1} #{n2} 2>/dev/null`
		next if not data
		
		data.strip!
		head,dead = data.split(/\s+/, 2)
		next if not head
		
		p head
		
	end
end

