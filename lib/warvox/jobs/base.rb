module WarVOX
module Jobs
class Base
	attr_accessor :name, :status
	
	def type
		'base'
	end
	
	def name
		'noname'
	end
	
	def stop
		@status = 'active'
	end
	
	def start
		@status = 'completed'
	end
end
end
end

