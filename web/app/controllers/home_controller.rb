class HomeController < ApplicationController
	layout 'warvox'
	
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
end
