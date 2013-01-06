# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def select_tag_for_filter(nvpairs, params)
	  _url = ( url_for :overwrite_params => { }).split('?')[0]
	  _html = %{<span class="pull-left filter-label">Filter: </span> }
	  _html << %{<select name="show" class="filter-select" }
	  _html << %{onchange="window.location='#{_url}' + '?show=' + this.value"> }
	  nvpairs.each do |pair|
    	_html << %{<option value="#{h(pair[:scope])}" }
    	if params[:show] == pair[:scope] || ((params[:show].nil? || params[:show].empty?) && pair[:scope] == "all")
    	  _html << %{ selected="selected" }
    	end
    	_html << %{>#{pair[:label]} }
    	_html << %{</option>}
	  end
	  _html << %{</select>}
	  raw(_html)
	end

	def select_match_scope(nvpairs, params)
	  _url = ( url_for :overwrite_params => { }).split('?')[0]
	  _html = %{<span class="pull-left filter-label">Matching Scope: </span> }
	  _html << %{<select name="match_scope" class="filter-select" }
	  _html << %{onchange="window.location='#{_url}' + '?match_scope=' + this.value"> }
	  nvpairs.each do |pair|
    	_html << %{<option value="#{h(pair[:scope])}" }
    	if params[:match_scope] == pair[:scope] || ((params[:match_scope].nil? || params[:match_scope].empty?) && pair[:scope] == "job")
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
				ttip << raw("<div class='task_args_var'>") + h(truncate(k.to_s, :length => 20)) + raw(": </div> ")
				ttip << raw("<div class='task_args_val'>") + h(truncate((v.to_s), :length => 20)) + raw("&nbsp;</div>")
			end
			ttip << raw("</div>\n")
			outp = raw("<span class='xpopover' rel='popover' data-title=\"#{job.task.capitalize} Task ##{job.id}\" data-content=\"#{ttip}\">#{h job.task.capitalize}</span>")
			outp
		rescue ::Exception => e
			job.status.to_s.capitalize
		end
	end

	def format_call_type_details(call)
			ttip = raw("<div class='task_args_formatted'>")


			ttip << raw("<div class='task_args_var'>Call Time:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.created_at.strftime("%Y-%m-%d %H:%M:%S %Z")) + raw("&nbsp;</div>")

			ttip << raw("<div class='task_args_var'>CallerID:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.caller_id) + raw("&nbsp;</div>")

			ttip << raw("<div class='task_args_var'>Provider:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.provider.name) + raw("&nbsp;</div>")


			ttip << raw("<div class='task_args_var'>Audio:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.audio_length.to_s) + raw("&nbsp;</div>")


			ttip << raw("<div class='task_args_var'>Ring:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.ring_length.to_s) + raw("&nbsp;</div>")

			ttip << raw("</div>\n")
			outp = raw("<span class='xpopover' rel='popover' data-title=\"#{h call.number.to_s }\" data-content=\"#{ttip}\"><strong>#{h call.line_type.upcase }</strong></span>")
			outp
	end


	def format_job_status(job)
		case job.status
		when 'error'
			ttip = h(job.error.to_s)
			outp = raw("<span class='xpopover' rel='popover' data-title=\"Task Details\" data-content=\"#{ttip}\">#{h job.status.capitalize}</span>")
			outp
		else
			job.status.to_s.capitalize
		end

	end
end
