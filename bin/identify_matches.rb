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
	$stderr.puts "Usage: #{$0} [job|all] <fprint>"
	exit
end

#
# Script
#

job = ARGV.shift
fp  = ARGV.shift

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

fp  = $stdin.read.strip if fp == "-"
job = nil if job.downcase == "all"

if not fp
	usage()
end


begin
	res = nil
	job = DialJob.find(job.to_i) if job
	if job
		res = DialResult.find_by_sql "SELECT dial_results.*,  " +
			" (( icount('#{fp}'::int[] & dial_results.fprint::int[]) / icount('#{fp}'::int[])::float ) * 100.0 ) AS matchscore " +
			"FROM dial_results " +
			"WHERE " +
			" icount(dial_results.fprint) > 0 AND " +
			" dial_results.dial_job_id = '#{job.id}' " +
			"ORDER BY matchscore DESC"
	else
		res = DialResult.find_by_sql "SELECT dial_results.*,  " +
			" (( icount('#{fp}'::int[] & dial_results.fprint::int[]) / icount('#{fp}'::int[])::float ) * 100.0 ) AS matchscore " +
			"FROM dial_results " +
			"WHERE " +
			" icount(dial_results.fprint) > 0 " +
			"ORDER BY matchscore DESC"
	end
	res.each do |r|
		$stdout.puts "#{"%.2f" % r.matchscore}\t#{r.dial_job_id}\t#{r.number}"
	end
rescue ActiveRecord::RecordNotFound
	$stderr.puts "Job not found"
	exit
end
