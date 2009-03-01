module WarVOX
class JobQueue
	attr_accessor :active_job, :active_thread, :queue, :queue_thread

	def initialize
		@queue = []
		@queue_thread = Thread.new{ manage_queue }
		super
	end
	
	# XXX synchronize
	def deschedule(job_id)

		if(@active_job and @active_job.name == job_id)
			@active_thread.kill
			@active_job = @active_thread = nil
		end
		
		res = []
		@queue.each do |j|
			res << j if j.name == job_id
		end
		
		if(res.length > 0)
			res.each {|j| @queue.delete(j) }
		end
	end
	
	def schedule(job)
		@queue.push(job)
	end
	
	def manage_queue
		begin
		while(true)
			if(@active_job and @active_job.status == 'completed')
				@active_job    = nil
				@active_thread = nil
			end
			
			if(not @active_job and @queue.length > 0)
				@active_job    = @queue.shift
				@active_thread = Thread.new { @active_job.start }
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
