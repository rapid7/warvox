# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def select_tag_for_filter(nvpairs, params)
	  _url = ( url_for :overwrite_params => { }).split('?')[0]
	  _html = %{<label for="show">Filter: </label> }
	  _html << %{<select name="show" id="show" }
	  _html << %{onchange="window.location='#{_url}' + '?show=' + this.value"> }
	  nvpairs.each do |pair|
    	_html << %{<option value="#{pair[:scope]}" }
    	if params[:show] == pair[:scope] || ((params[:show].nil? || params[:show].empty?) && pair[:scope] == "all")
    	  _html << %{ selected="selected" }
    	end
    	_html << %{>#{pair[:label]} }
    	_html << %{</option>}
	  end
	  _html << %{</select>}
	  raw(_html)
	end

	def set_focus(element_id)
		javascript_tag(" $elem = $(\"#{element_id}\"); if (null !== $elem && $elem.length > 0){$elem.focus()}")
	end

	def format_job_details(job)
		begin
			info = Marshal.load(job.args.to_s)

			ttip = raw("<div class='task_args_formatted'>")
			info.each_pair do |k,v|
				ttip << raw("<div class='task_args_var'>") + k.to_s.html_safe + raw(": </div> ")
				ttip << raw("<div class='task_args_val'>") + v.to_s.html_safe + raw("&nbsp;</div>")
			end
			ttip << raw("</div>\n")
			outp = raw("<a href='#' rel='tooltip' title=\"#{ttip}\" data-html='true'>#{job.task.capitalize.html_safe}</a>")
			outp
		rescue ::Exception => e
			job.status.to_s.capitalize
		end
	end

	def format_job_status(job)
		case job.status
		when 'error'
			ttip = job.error.to_s.html_safe
			outp = raw("<a href='#' rel='tooltip' title=\"#{ttip}\" data-html='true'>#{job.status.capitalize.html_safe}</a>")
			outp
		else
			job.status.to_s.capitalize
		end

	end
end
