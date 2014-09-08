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

@task = nil
@job  = nil

def usage
	$stderr.puts "Usage: #{$0} [JID]"
	exit(1)
end

def stop
	if @task
		@task.stop() rescue nil
	end
	if @job
		Job.where(id: @job_id).update_all({ status: 'stopped', completed_at: Time.now })
	end
	exit(0)
end

#
# Script
#

jid = ARGV.shift() || usage()
if (jid and jid =="-h") or (! jid)
	usage()
end

require 'config/boot'
require 'config/environment'

trap("SIGTERM") { stop() }

jid = jid.to_i

@job = Job.where(id: jid).first

unless @job
	$stderr.puts "Error: Specified job not found"
	WarVOX::Log.warn("Worker rejected invalid Job #{jid}")
	exit(1)
end

$0 = "warvox worker: #{jid} "

Job.where(id: @job.id).update_all({ started_at: Time.now.utc, status: 'running'})

args = Marshal.load(@job.args) rescue {}


WarVOX::Log.debug("Worker #{@job.id} #{@job.task} is running #{@job.task} with parameters #{ args.inspect }")

begin

case @job.task
when 'dialer'
	@task = WarVOX::Jobs::Dialer.new(@job.id, args)
	@task.start
when 'analysis'
	@task = WarVOX::Jobs::Analysis.new(@job.id, args)
	@task.start
else
	Job.where(id: @job.id).update_all({ error: 'unsupported', status: 'error' })
end

@job.update_progress(100)

rescue ::SignalException, ::SystemExit
	raise $!
rescue ::Exception => e
	WarVOX::Log.warn("Worker #{@job.id} #{@job.task} threw an exception: #{e.class} #{e} #{e.backtrace}")
	Job.where(id: @job.id).update_all({ error: "Exception: #{e.class} #{e}", status: 'error', completed_at: Time.now.utc })
end
