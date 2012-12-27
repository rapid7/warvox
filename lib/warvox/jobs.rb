module WarVOX
class JobQueue
	attr_accessor :active_job, :active_thread, :queue, :queue_thread

	require "thread"
	
	def initialize
		@mutex = ::Mutex.new	
		@queue = []
		@queue_thread = Thread.new{ manage_queue }
		
		super
	end
	
	def scheduled?(klass, job_id)
		@mutex.synchronize do
			[@active_job, *(@queue)].each do |c|
				next if not c
				return true if (c.class == klass and c.name == job_id)
			end
		end
		false
	end
	
	def schedule(klass, job_id)
		begin
		return false if scheduled?(klass, job_id)
		@queue.push(klass.new(job_id))
		rescue ::Exception => e
			$stderr.puts "ERROR!!!!!: #{e} #{e.backtrace}"
			false
		end
	end
	
	def manage_queue
		begin
		while(true)
			@mutex.synchronize do
				if(@active_job and @active_job.status == 'completed')
					@active_job    = nil
					@active_thread = nil
				end

				if(not @active_job and @queue.length > 0)
					@active_job    = @queue.shift
					@active_thread = Thread.new { @active_job.start }
				end
			end

			Kernel.select(nil, nil, nil, 1)
		end
		rescue ::Exception
			$stderr.puts "QUEUE MANAGER:#{$!.class} #{$!}"
			$stderr.flush
		end
	end	

end
end


require 'warvox/jobs/base'
require 'warvox/jobs/dialer'
require 'warvox/jobs/analysis'
