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
	$stderr.puts "Usage: #{$0} [Input Dir] <Job ID>"
	exit(1)
end

#
# Script
#

dir = ARGV.shift
jid = ARGV.shift

if (dir and dir =="-h") or (! dir)
	usage()
end

provider = Provider.first
unless provider
	provider = Provider.create(
		:name  => 'Import Provider',
		:host  => 'localhost',
		:port  => 4369,
		:user  => "null",
		:pass  => "null",
		:lines => 1,
		:enabled => false
	)
end

job = nil
if jid
	job = DialJob.find(jid.to_i)
	unless job
		$stderr.puts "Error: Specified Job ID not found"
		exit(1)
	end
else
	job = DialJob.new
	job.range        = "IMPORTED"
	job.seconds      = 60
	job.lines        = 1
	job.cid_mask     = "XXXXX"
	job.status       = "completed"
	job.progress     = 100
	job.started_at   = Time.now
	job.completed_at = Time.now
	job.processed    = false
	job.save
end

Dir["#{dir}/**/*.raw"].each do |rfile|
	num, ext = File.basename(rfile).split(".", 2)
	dr = DialResult.new
	dr.dial_job_id = job[:id]
	dr.number      = num
	dr.provider_id = provider[:id]
	dr.completed   = true
	dr.busy        = false
	dr.seconds     = File.size(rfile) / 16000.0
	dr.ringtime    = 0
	dr.processed   = false
	dr.cid         = num
	dr.save

	mr = dr.media
	::File.open(rfile, "rb") do |fd|
		mr.audio = fd.read(fd.stat.size)
		mr.save
	end

	$stdout.puts "[*] Imported #{num}"
end
