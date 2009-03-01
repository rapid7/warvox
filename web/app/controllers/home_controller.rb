class HomeController < ApplicationController
	layout 'warvox'
	
	def index
		begin
			@kissfft_loaded = false
			require 'kissfft'
			@kissfft_loaded = true
		rescue
		end
	end
	
	def about
	end
end
