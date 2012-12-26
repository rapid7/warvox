#!/usr/bin/env ruby

$:.unshift(::File.join(::File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require "rex/proto/iax2"
require "optparse"

parser = OptionParser.new
opts   = { 
	:recording_time => 52 
}

parser.banner = "Usage: #{$0} [options]"
parser.on("-s server") do |v|
	opts[:server_host] = v
end
	
parser.on("-u user") do |v|
	opts[:username] = v
end	

parser.on("-p pass") do |v|
	opts[:password] = v
end

parser.on("-o output") do |v|
	opts[:output] = v
end	

parser.on("-n number") do |v|
	opts[:called_number] = v 
end

parser.on("-c cid") do |v|
	opts[:caller_number] = v 
end	

parser.on("-l seconds") do |v|
	opts[:recording_time] = v.to_i
end	

parser.on("-d") do |v|
	opts[:debugging] = true
end	

parser.on("-h") do
	$stderr.puts parser
	exit(1)
end
		
parser.parse!(ARGV)

if not (opts[:server_host] and opts[:username] and opts[:password] and opts[:called_number] and opts[:output])
	$stderr.puts parser
	exit(1)	
end


cli = Rex::Proto::IAX2::Client.new(opts)

reg = cli.create_call
r   = reg.register
if not r 
	$stderr.puts "ERROR: Unable to register with the IAX server"
	exit(0)
end

c = cli.create_call
r = c.dial( opts[:called_number] )
if not r
	$stderr.puts "ERROR: Unable to dial the requested number"
	exit(0)
end

begin

::Timeout.timeout( opts[:recording_time] ) do 
	while (c.state != :hangup)
		case c.state
		when :ringing
		when :answered
		when :hangup
			break
		end
		select(nil,nil,nil, 0.25)
	end
end
rescue ::Timeout::Error
ensure
	c.hangup rescue nil
end

cli.shutdown

cnt = 0
fd = ::File.open( opts[:output], "wb")
c.each_audio_frame do |frame|
	fd.write(frame)
	cnt += frame.length
end
fd.close

$stdout.puts "COMPLETED: BYTES=#{cnt} RINGTIME=#{c.ring_time} FILE=#{ ::File.expand_path( opts[:output] ) } BUSY=#{c.busy ? 1 : 0} FAIL=#{cnt == 0 ? 1 : 0}"

