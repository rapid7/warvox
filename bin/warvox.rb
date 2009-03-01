#!/usr/bin/env ruby
###################

#
# Load the library path
# 
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end

voxroot = File.join(File.dirname(base), '..', 'web')
Dir.chdir(voxroot)
require 'getoptlong'

voxserv = File.join('script', 'server')

def usage
	$stderr.puts "#{$0} [--address IP] [--port PORT] --background"
	exit(0)
end

opts    = 
{
	'ServerPort' => 7777,
	'ServerHost' => '127.0.0.1',
	'Background' => false,
}

args = GetoptLong.new(
	["--address", "-a", GetoptLong::REQUIRED_ARGUMENT ],
	["--port", "-p", GetoptLong::REQUIRED_ARGUMENT ],
	["--daemon", "-d", GetoptLong::NO_ARGUMENT ],
	["--help", "-h", GetoptLong::NO_ARGUMENT]
)

args.each do |opt,arg|
	case opt
	when '--address'
		opts['ServerHost'] = arg
	when '--port'
		opts['ServerPort'] = arg
	when '--daemon'
		opts['Background'] = true
	when '--help'
		usage()
	end
end


# Clear ARGV
while(ARGV.length > 0)
	ARGV.shift
end

# Rebuild ARGV
[
	'-p', opts['ServerPort'].to_s, 
	'-b', opts['ServerHost'],
	'-e', 'production',
	(opts['Background'] ? '-d' : '')
].each do |arg|
	ARGV.push arg
end

$browser_url   = "http://#{opts['ServerHost']}:#{opts['ServerPort']}/"

$stderr.puts ""
$stderr.puts "[*] Starting WarVOX on #{$browser_url}"
$stderr.puts ""

load(voxserv)
