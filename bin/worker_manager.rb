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

@worker_path = File.expand_path(File.join(File.dirname(base), "worker.rb"))

require 'warvox'
require 'socket'

ENV['RAILS_ENV'] ||= 'production'

$:.unshift(File.join(File.expand_path(File.dirname(base)), '..'))
require 'config/boot'
require 'config/environment'


@jobs = []

def stop
	WarVOX::Log.info("Worker Manager is terminating due to signal")

	unless @jobs.length > 0
		exit(0)
	end

	# Update the database
	Job.update_all({ :status => "stopped", :completed_at => Time.now.utc}, { :id => @jobs.map{|j| j[:id] } })

	# Signal running jobs to shut down
	@jobs.map{|j| Process.kill("TERM", j[:pid]) rescue nil }

	# Sleep for five seconds
	sleep(5)

	# Forcibly kill any remaining job processes
	@jobs.map{|j| Process.kill("KILL", j[:pid]) rescue nil }

	exit(0)
end


def clear_zombies
	while ( r = Process.waitpid(-1, Process::WNOHANG) rescue nil ) do
	end
end

def schedule_job(j)
	WarVOX::Log.debug("Worker Manager is launching job #{j.id}")
	@jobs <<  {
		:id  => j.id,
		:pid => Process.fork { exec("#{@worker_path} #{j.id}") }
	}
end

def stop_cancelled_jobs
	jids = []
	@jobs.each do |x|
		jids << x[:id]
	end

	return if jids.length == 0
	Job.where(:status => 'cancelled', :id => jids).find_each do |j|
		job = @jobs.select{ |o| o[:id] == j.id }.first
		next unless job and job[:pid]
		pid = job[:pid]

		WarVOX::Log.debug("Worker Manager is killing job #{j.id} with PID #{pid}")
		Process.kill('TERM', pid)
	end
end

def clear_completed_jobs
	dead_pids = []
	dead_jids = []

	@jobs.each do |j|
		alive = Process.kill(0, j[:pid]) rescue nil
		next if alive
		dead_pids << j[:pid]
		dead_jids << j[:id]
	end

	return unless dead_jids.length > 0

	WarVOX::Log.debug("Worker Manager is clearing #{dead_pids.length} completed jobs")

	@jobs = @jobs.reject{|x| dead_pids.include?( x[:pid] ) }

	# Mark failed/crashed jobs as completed
	Job.where(id: dead_jids, completed_at: nil).update_all({completed_at: Time.now.utc})
end

def clear_stale_jobs
	jids  = @jobs.map{|x| x[:id] }
	stale = nil

	if jids.length > 0
		stale = Job.where("completed_at IS NULL AND locked_by LIKE ? AND id NOT IN (?)", Socket.gethostname + "^%", jids)
	else
		stale = Job.where("completed_at IS NULL AND locked_by LIKE ?", Socket.gethostname + "^%")
	end

	dead = []
	pids = {}

	# Extract the PID from the locked_by cookie for each job
	stale.each do |j|
		host, pid, uniq = j.locked_by.to_s.split("^", 3)
		next unless (pid and uniq)
		pids[pid] ||= []
		pids[pid]  << j
	end

	# Identify dead processes (must be same user or root)
	pids.keys.each do |pid|
		alive =	Process.kill(0, pid.to_i) rescue nil
		next if alive
		pids[pid].each do |j|
			dead << j.id
		end
	end

	# Mark these jobs as abandoned
	if dead.length > 0
		WarVOX::Log.debug("Worker Manager is marking #{dead.length} jobs as abandoned")
		Job.where(:id => dead).update_all({locked_by: nil, status: 'abandoned'})
	end
end

def schedule_submitted_jobs
	loop do
		# Look for a candidate job with no current owner
		j  = Job.where(status: 'submitted', locked_by: nil).limit(1).first
		return unless j

		# Try to get a lock on this job
		Job.where(id: j.id, locked_by: nil).update_all({locked_by: @cookie, locked_at: Time.now.utc, status: 'scheduled'})

		# See if we actually got the lock
		j  = Job.where(id: j.id, status: 'scheduled', locked_by: @cookie).limit(1).first

		# Try again if we lost the race,
		next unless j

		# Hurray, we got a job, run it
		schedule_job(j)

		return true
	end
end

#
# Main
#

trap("SIGINT")  { stop() }
trap("SIGTERM") { stop() }

@cookie   = Socket.gethostname + "^" + $$.to_s + "^" + sprintf("%.8x", rand(0x100000000))
@max_jobs = 3


WarVOX::Log.info("Worker Manager initialized with cookie #{@cookie}")

loop do
	$0 = "warvox manager: #{@jobs.length} active jobs (cookie : #{@cookie})"

	# Clear any zombie processes
	clear_zombies()

	# Clear any completed jobs
	clear_completed_jobs()

	# Stop any jobs cancelled by the user
	stop_cancelled_jobs()

	# Clear locks on any stale jobs from this host
	clear_stale_jobs()

	while @jobs.length < @max_jobs
		break unless schedule_submitted_jobs
	end

	# Sleep between 3-8 seconds before re-entering the loop
	sleep(rand(5) + 3)
end
