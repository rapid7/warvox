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
	$stderr.puts "#{$0} [/path/to/audio/] [output.db]"
	exit
end

src = ARGV.shift || usage
dst = ARGV.shift || usage
db  = File.new(dst, "w")
dir = Dir.new(src)
cnt = 0

set = dir.entries.sort.grep(/\.raw/)
set.each do |ent|
	next if not ent =~ /\.raw/
	puts "[*] [#{sprintf("%.5d/%.5d", cnt+1, set.length)}] Processing #{ent}..."
	raw = WarVOX::Audio::Raw.from_file( File.join(src, ent) )
	db.write( ent.gsub(/\.raw|\.gz/, '') + " " + raw.to_flow + "\n" )
	cnt += 1
end

db.close

puts "[*] Wrote #{cnt} database entries into #{dst}"
