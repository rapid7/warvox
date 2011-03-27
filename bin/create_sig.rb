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
require 'yaml'

#
# Script
# 

def usage
	$stderr.puts "#{$0} [raw-file] <skip-count> <length-count>"
	exit(1)
end

inp = ARGV.shift() || usage()
skp = (ARGV.shift() || 0).to_i
len = (ARGV.shift() || 0).to_i

raw = WarVOX::Audio::Raw.from_file(inp)
raw.samples = (raw.samples[skp, raw.samples.length]||[]) if skp > 0
raw.samples = (raw.samples[0, len]||[]) if len > 0

if(raw.samples.length == 0)
	$stderr.puts "Error: the sample length is too short to create a signature"
	exit(1)
end


$stdout.puts raw.to_freq_sig_txt
