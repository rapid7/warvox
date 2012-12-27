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
require 'fileutils'


ENV['RAILS_ENV'] ||= 'production'

$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))
require 'config/boot'
require 'config/environment'

def usage
	$stderr.puts "Usage: #{$0} [Output Dir] [Job ID] <Type>"
	exit
end

#
# Script
#

dir = ARGV.shift
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


::FileUtils.mkdir_p(dir)

begin
	cnt = 0
	job = DialJob.find(job.to_i)
	job.dial_results.each do |r|
		next if not r.number
		next if r.audio.to_s.length == 0
		out = ::File.join(dir, "#{r.number}.raw")
		::File.open(out, "wb") do |fd|
			fd.write( r.audio )
		end
		cnt += 1
	end
	$stderr.puts "Wrote #{cnt} audio files to #{dir}"
rescue ActiveRecord::RecordNotFound
	$stderr.puts "Job not found"
	exit
end
