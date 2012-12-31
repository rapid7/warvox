class HomeController < ApplicationController

	def index

	end

	def about
		begin
			@has_kissfft = "MISSING"
			require 'kissfft'
			@has_kissfft = $LOADED_FEATURES.grep(/kissfft/)[0]
		rescue ::LoadError
		end
	end

	def help
	end

	def check
		@has_project  = ( Project.count > 0 )
		@has_provider = ( Provider.count > 0 )
		@has_job      = ( DialJob.count > 0 )
		@has_result   = ( DialResult.where(:completed => true ).count > 0 )
		@has_analysis = ( DialResult.where(:processed => true ).count > 0 )
	end

end
