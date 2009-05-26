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
	require 'kissfft'
	puts "[*] The KissFFT module appears to be available"
rescue ::LoadError
	puts "[*] ERROR: The KissFFT module has not been installed"
	exit
end

sox_path = WarVOX::Config.tool_path('sox')
if(not sox_path)
	puts "[*] ERROR: The 'sox' binary could not be found"
	exit
end

sox_data = `#{sox_path} --help 2>&1`
if(sox_data !~ /raw/)
	puts "[*] ERROR: The 'sox' binary does not have support for RAW audio"
	exit
end
puts "[*] The SOX binary appears to be available with RAW file support"


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


if(not WarVOX::Config.tool_path('iaxrecord'))
	puts "[*] ERROR: The 'iaxrecord' binary could not be installed"
	exit
end
puts "[*] The IAXRECORD binary appears to be available"

if(not WarVOX::Config.tool_path('dtmf2num'))
	puts "[*] ERROR: The 'dtmf2num' binary could not be installed"
	exit
end
puts "[*] The DTMF2NUM binary appears to be available"


puts " "
puts "[*] Congratulations! You are now ready to run WarVOX"
puts "[*] Start WarVOX with bin/warvox.rb"
puts " "
