#!/usr/bin/env ruby
###################

require 'getoptlong'
require 'open3'

#
# Load the library path
#
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end

$:.unshift(File.join(File.expand_path(File.dirname(base)), '..', 'lib'))

voxroot = File.expand_path(File.join(File.dirname(base), '..'))
voxserv = File.expand_path(File.join(File.expand_path(voxroot), 'script', 'rails'))
manager = File.expand_path(File.join(File.dirname(base), 'worker_manager.rb'))

require 'warvox'


Dir.chdir(voxroot)

def stop
	$stderr.puts "[-] Interrupt received, shutting down workers and web server..."
	Process.kill("TERM", @manager_pid) if @manager_pid
	exit(0)
end

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
	'-e', 'production',
]

if opts['Background']
	args.push("-d")
end


trap("SIGINT") { stop() }

$browser_url   = "http://#{opts['ServerHost']}:#{opts['ServerPort']}/"

$stderr.puts ""
$stderr.puts "[*] Starting WarVOX on #{$browser_url}"
$stderr.puts ""


WarVOX::Log.info("WarVOX is starting up...")

@manager_pid = Process.fork()
if not @manager_pid
	while ARGV.shift do
	end
	load(manager)
	exit(0)
end

WarVOX::Log.info("Worker Manager has PID #{@manager_pid}")

@webserver_pid = $$

WarVOX::Log.info("Web Server has PID #{@manager_pid}")

while(ARGV.length > 0); ARGV.shift; end
args.each {|arg| ARGV.push(arg) }

load(voxserv)
