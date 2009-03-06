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

inp = ARGV.shift || exit(0)
$0  = "warvox(analyzer): #{inp}"

$stdout.write(
	WarVOX::Jobs::CallAnalysis.new(
		0
	).analyze_call(
		inp
	).to_yaml
)
