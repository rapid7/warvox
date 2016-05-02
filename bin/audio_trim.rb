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
  $stderr.puts "Usage: #{$0} [offset] [length] <input.raw> <output.raw>"
  exit
end

# TODO: Needs WAV header support

#
# Script
#

off = ARGV.shift
len = ARGV.shift
inp = ARGV.shift
out = ARGV.shift

if (off and off == "-h") or not off
  usage()
end

buf = ''
ifd = nil

if inp
  ifd = ::File.open(inp, "rb")
else
  $stdin.binmode
  ifd = $stdin
end

ofd = nil

if out
  ofd = ::File.open(out, "wb")
else
  $stdout.binmode
  ofd = $stdout
end


buf = ifd.read
off = off.to_i * 16000
len = (len.to_i > 0) ? len.to_i : (buf.length / 16000).to_i

ofd.write( buf[off, len * 16000] )
exit(0)



