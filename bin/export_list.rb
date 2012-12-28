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
require 'csv'

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

fields = %W{ number line_type cid completed busy seconds ringtime peak_freq notes signatures }
begin
	$stdout.puts fields.to_csv
	DialResult.where(:dial_job_id => job.to_i).find(:order => :number) do |r|
		next if not r.number
		if(not typ or typ.downcase == (r.line_type||"").downcase)
			out = []
			fields.each do |f|
				out << r[f].to_s
			end
			$stdout.puts out.to_csv
		end
	end
rescue ActiveRecord::RecordNotFound
	$stderr.puts "Job not found"
	exit
end
