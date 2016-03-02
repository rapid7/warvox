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

def usage
  $stderr.puts "Usage: #{$0} <input.raw> <output.wav>"
  exit
end

#
# Script
#

inp = ARGV.shift
out = ARGV.shift

if (inp and inp == "-h") or not inp
  usage()
end

raw = WarVOX::Audio::Raw.from_file(inp)
if out 
  ::File.open(out, "wb") do |fd|
    fd.write(raw.to_wav)
  end
else 
  $stdout.write(raw.to_wav)
end
