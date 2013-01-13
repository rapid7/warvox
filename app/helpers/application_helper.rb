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

	def format_job_rate(job)
		pluralize( (job.rate * 60.0).to_i, "call") + "/min"
	end

	#
	# Includes any javascripts specific to this view. The hosts/show view
	# will automatically include any javascripts at public/javascripts/hosts/show.js.
	#
	# @return [void]
	def include_view_javascript
		#
		# Sprockets treats index.js as special, so the js for the index action must be called _index.js instead.
		# http://guides.rubyonrails.org/asset_pipeline.html#using-index-files
		#

		controller_action_name = controller.action_name

		if controller_action_name == 'index'
			safe_action_name = '_index'
		else
			safe_action_name = controller_action_name
		end

		include_view_javascript_named(safe_action_name)
	end

	# Includes the named javascript for this controller if it exists.
	#
	# @return [void]
	def include_view_javascript_named(name)

		controller_path = controller.controller_path
		extensions = ['.coffee', '.js.coffee']
		javascript_controller_pathname = Rails.root.join('app', 'assets', 'javascripts', controller_path)
		pathnames = extensions.collect { |extension|
			javascript_controller_pathname.join("#{name}#{extension}")
		}

		if pathnames.any?(&:exist?)
			path = File.join(controller_path, name)
			content_for(:view_javascript) do
				javascript_include_tag path
			end
		end
	end

	def escape_javascript_dq(str)
		escape_javascript(str.strip).gsub("\\'", "'").gsub("\t", "    ")
	end

	def submit_checkboxes_to(name, path, html={})
		if html[:confirm]
			confirm = html.delete(:confirm)
			link_to(name, "#", html.merge({:onclick => "if(confirm('#{h confirm}')){ submit_checkboxes_to('#{path}','#{form_authenticity_token}')}else{return false;}" }))
		else
			link_to(name, "#", html.merge({:onclick => "submit_checkboxes_to('#{path}','#{form_authenticity_token}')" }))
		end
	end

	# Scrub out data that can break the JSON parser
	#
	# data - The String json to be scrubbed.
	#
	# Returns the String json with invalid data removed.
	def json_data_scrub(data)
		data.to_s.gsub(/[\x00-\x1f]/){ |x| "\\x%.2x" % x.unpack("C*")[0] }
	end

	# Returns the properly escaped sEcho parameter that DataTables expects.
	def echo_data_tables
		h(params[:sEcho]).to_json.html_safe
	end

	# Generate the markup for the call's row checkbox.
	# Returns the String markup html, escaped for json.
	def call_checkbox_tag(call)
		check_box_tag("result_ids[]", call.id, false, :id => nil).to_json.html_safe
	end

	def call_number_html(call)
		json_data_scrub(h(call.number)).to_json.html_safe
	end

	def call_caller_id_html(call)
		json_data_scrub(h(call.caller_id)).to_json.html_safe
	end

	def call_provider_html(call)
		json_data_scrub(h(call.provider.name)).to_json.html_safe
	end

	def call_answered_html(call)
		json_data_scrub(h(call.answered ? "Yes" : "No")).to_json.html_safe
	end

	def call_busy_html(call)
		json_data_scrub(h(call.busy ? "Yes" : "No")).to_json.html_safe
	end

	def call_audio_length_html(call)
		json_data_scrub(h(call.audio_length.to_s)).to_json.html_safe
	end

	def call_ring_length_html(call)
		json_data_scrub(h(call.ring_length.to_s)).to_json.html_safe
	end


end
