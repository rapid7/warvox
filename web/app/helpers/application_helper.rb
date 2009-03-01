# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def get_sections
		
		count    = 0
		html     = ""
		asection = nil

		sections = 
		[
			{ :name => 'Home',         :link => '/',              :controller => 'home',          :subsections => [

			] },
			{ :name => 'Jobs' ,        :link => '/dial_jobs/',    :controller => 'dial_jobs',     :subsections => [
				# 
			] },
			{ :name => 'Results',      :link => '/dial_results/', :controller => 'dial_results',  :subsections => [
				# 
			] },
			{ :name => 'Analysis',     :link => '/analyze/',      :controller => 'analyze',       :subsections => [
				# 
			] },					
			{ :name => 'Providers',    :link => '/providers/',    :controller => 'providers',     :subsections => [
				# 
			] },
			{ :name => 'About',        :link => '/home/about/',   :controller => 'home/about',    :subsections => [
				# 
			] }			
		]
		
		html << "<div id='sections_container'>\n"
		html << "<ul id='sections_ul'>\n"
		sections.each do |section|
			lactive = ''
			if (params[:controller] == section[:controller])
				lactive = "id='sections_active'"
				asection = section
			end
			html << "<li><a #{lactive} href='#{section[:link]}'>#{section[:name]}</a></li>";
		end
		html << "\n</ul></div>\n"
		
		count = 0
		html << "<div id='subsections_container'>\n"
		html << "<ul id='subsections_ul'>\n"
		(asection ? asection[:subsections] : [] ).each do |section|
			html << "<li><a href='#{section[:link]}'>#{section[:name]}</a></li>";
		end
		html << "\n</ul></div>\n"
	end
end
