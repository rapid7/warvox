#!/usr/bin/env ruby
###################

require 'getoptlong'


#
# Load the library path
# 
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end

voxroot = File.join(File.dirname(base), '..', 'web')
voxserv = File.join(File.expand_path(voxroot), 'script', 'rails')

Dir.chdir(voxroot)

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

args = [
	'server',
	'-p', opts['ServerPort'].to_s, 
	'-b', opts['ServerHost'],
	'-e', 'development',
]

if opts['Background']
	args.push("-d")
end

$browser_url   = "http://#{opts['ServerHost']}:#{opts['ServerPort']}/"

$stderr.puts ""
$stderr.puts "[*] Starting WarVOX on #{$browser_url}"
$stderr.puts ""

while(ARGV.length > 0); ARGV.shift; end
args.each {|arg| ARGV.push(arg) }

load(voxserv)
