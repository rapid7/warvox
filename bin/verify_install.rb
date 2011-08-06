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
# Verify that WarVOX has been installed properly
#

puts("**********************************************************************")
puts("*                                                                    *")
puts("*                  WarVOX Installation Verifier                      *")
puts("*                                                                    *")
puts("**********************************************************************")
puts(" ")


begin
	require 'rubygems'
	puts "[*] RubyGems have been installed"
rescue ::LoadError
	puts "[*] ERROR: The RubyGems package has not been installed:"
	puts "    $ sudo apt-get install rubygems"
	exit
end

begin
	require 'bundler'
	puts "[*] The Bundler gem has been installed"
rescue ::LoadError
	puts "[*] ERROR: The Bundler gem has not been installed:"
	puts "    $ sudo gem install bundler"	
	exit
end

begin 
	require 'kissfft'
	puts "[*] The KissFFT module appears to be available"
rescue ::LoadError
	puts "[*] ERROR: The KissFFT module has not been installed"
	exit
end

if(not WarVOX::Config.tool_path('gnuplot'))
	puts "[*] ERROR: The 'gnuplot' binary could not be installed"
	exit
end
puts "[*] The GNUPlot binary appears to be available"

if(not WarVOX::Config.tool_path('lame'))
	puts "[*] ERROR: The 'lame' binary could not be installed"
	exit
end
puts "[*] The LAME binary appears to be available"


if(not WarVOX::Config.tool_path('dtmf2num'))
	puts "[*] ERROR: The 'dtmf2num' binary could not be installed"
	exit
end
puts "[*] The DTMF2NUM binary appears to be available"


puts " "
puts "[*] Congratulations! You are now ready to run WarVOX"
puts "[*] Start WarVOX with bin/warvox.rb"
puts " "
