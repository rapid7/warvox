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
				ttip << raw("<div class='task_args_var'>") + h(k.to_s) + raw(": </div> ")
				ttip << raw("<div class='task_args_val'>") + h(v.to_s) + raw("&nbsp;</div>")
			end
			ttip << raw("</div>\n")
			outp = raw("<span rel='tooltip' title=\"#{ttip}\" data-html='true' class='stooltip'>#{h job.task.capitalize}</span>")
			outp
		rescue ::Exception => e
			job.status.to_s.capitalize
		end
	end

	def format_job_status(job)
		case job.status
		when 'error'
			ttip = h(job.error.to_s)
			outp = raw("<span rel='tooltip' title=\"#{ttip}\" data-html='true' class='stooltip'>#{h job.status.capitalize}</span>")
			outp
		else
			job.status.to_s.capitalize
		end

	end
end
