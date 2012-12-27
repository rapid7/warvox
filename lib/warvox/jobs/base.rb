module WarVOX
module Jobs
class Base
	attr_accessor :name, :status

	def type
		'base'
	end

	def stop
		@status = 'active'
	end

	def start
		@status = 'completed'
	end

	def db_save(obj)
		max_tries = 100
		cur_tries = 0
		obj.save!
	end

	def clear_zombies
		begin
			# Clear zombies just in case...
			while(Process.waitpid(-1, Process::WNOHANG))
			end
		rescue ::Exception
		end
	end
end
end
end
