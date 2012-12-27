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

ENV['RAILS_ENV'] ||= 'production'

$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))
require 'config/boot'
require 'config/environment'

def usage
	$stderr.puts "Usage: #{$0} [Job ID] <Type>"
	exit
end

#
# Script
#

job = ARGV.shift
typ = ARGV.shift

if(job and job == "-h")
	usage()
end

if(not job)
	$stderr.puts "Listing all available jobs"
	$stderr.puts "=========================="
	DialJob.find(:all).each do |j|
		puts "#{j.id}\t#{j.started_at} --> #{j.completed_at}"
	end
	exit
end

begin
	job = DialJob.find(job.to_i)
	job.dial_results.sort{|a,b| a.number.to_i <=> b.number.to_i}.each do |r|
		next if not r.number
		if(not typ or typ.downcase == (r.line_type||"").downcase)
			puts "#{r.number}\t#{r.line_type}\tbusy=#{r.busy}\tring=#{r.ringtime}"
		end
	end
rescue ActiveRecord::RecordNotFound
	$stderr.puts "Job not found"
	exit
end
