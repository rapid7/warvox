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
require 'pry'

def usage
  $stderr.puts "Usage: #{$0} <inputA.raw> <inputB.raw>"
  exit
end

def log(m)
  $stderr.puts "[*] #{m}"
end

def score(a,b)
  (a & b).length / [a,b].max.length.to_f
end

#
# Script
#

inp1 = ARGV.shift
inp2 = ARGV.shift

if [inp1, inp2].include?("-h") or not (inp1 && inp2)
  usage()
end

# log("Processing #{inp1}...")
raw1 = WarVOX::Audio::Raw.from_file(inp1)
sig1 = raw1.to_freq_sig

# log("Processing #{inp2}...")
raw2 = WarVOX::Audio::Raw.from_file(inp2)
sig2 = raw2.to_freq_sig

puts "Score: #{score(sig1, sig2)}"
