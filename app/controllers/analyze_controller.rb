class AnalyzeController < ApplicationController

  def index
	@jobs = Job.paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30
	)
  end

  def view
  	@job_id   = params[:id]
  	@job      = Job.find(@job_id)
	@shown    = params[:show]

	ltypes = Call.find( :all, :select => 'DISTINCT line_type', :conditions => ["job_id = ?", @job_id] ).map{|r| r.line_type}
	res_types = {}

	ltypes.each do |k|
		next if not k
		res_types[k.capitalize.to_sym] = Call.count(
			:conditions => ['job_id = ? and line_type = ?', @job_id, k]
		)
	end

	@lines_by_type = res_types

    sort_by  = params[:sort_by] || 'number'
    sort_dir = params[:sort_dir] || 'asc'

    @results = []
    @results_total_count = @job.calls.where("job_id = ? AND analysis_completed_at IS NOT NULL", @job_id).count()

    if request.format.json?
      if params[:iDisplayLength] == '-1'
        @results_per_page = nil
      else
        @results_per_page = (params[:iDisplayLength] || 20).to_i
      end
      @results_offset = (params[:iDisplayStart] || 0).to_i

	  calls_search
      @results = @job.calls.includes(:provider).where(@search_conditions).limit(@results_per_page).offset(@results_offset).order(calls_sort_option)
      @results_total_display_count = @job.calls.includes(:provider).where(@search_conditions).count()
    end

	respond_to do |format|
      format.html
      format.json {
      	render :content_type => 'application/json', :json => render_to_string(:partial => 'view', :results => @results, :lines_by_type => @lines_by_type )
      }
    end

  end

  def view_matches
  	@result = Call.find(params[:call_id])
  	@job_id = @result.job_id
  	@match_scopes = [
  		{ :scope => 'job', :label => 'This Job' },
  		{ :scope => 'project', :label => 'This Project' },
  		{ :scope => 'global', :label => 'All Projects' }
  	]

  	@match_scope = params[:match_scope] || "job"

	@results = @result.paginate_matches(@match_scope, 30.0, params[:page], 30)
  end

  def resource
  	ctype = 'text/html'
	cpath = nil
	cdata = "File not found"

	res = CallMedium.where(:call_id => params[:result_id].to_i).first

	if res
		case params[:type]
		when 'big_sig'
			ctype = 'image/png'
			cdata = res.png_sig_freq
		when 'big_sig_dots'
			ctype = 'image/png'
			cdata = res.png_big_dots
		when 'small_sig'
			ctype = 'image/png'
			cdata = res.png_sig
		when 'big_freq'
			ctype = 'image/png'
			cdata = res.png_big_freq
		when 'small_freq'
			ctype = 'image/png'
			cdata = res.png_sig_freq
		when 'mp3'
			ctype = 'audio/mpeg'
			cdata = res.mp3
		when 'sig'
			ctype = 'text/plain'
			cdata = res.fprint
		when 'raw'
			ctype = 'octet/binary-stream'
			cdata = res.audio
		end
	end

    send_data(cdata, :type => ctype, :disposition => 'inline')
  end



  # Generate a SQL sort by option based on the incoming DataTables paramater.
  #
  # Returns the SQL String.
  def calls_sort_option
    column = case params[:iSortCol_0].to_s
             when '1'
               'number'
             when '2'
               'line_type'
             when '3'
               'peak_freq'
             end
    column + ' ' + (params[:sSortDir_0] =~ /^A/i ? 'asc' : 'desc') if column
  end

  def calls_search
  	@search_conditions = []
  	terms = params[:sSearch].to_s
  	terms = Shellword.shellwords(terms) rescue terms.split(/\s+/)
	where = "job_id = ? AND analysis_completed_at IS NOT NULL "
	param = [ @job_id ]
	glue  = "AND "
	terms.each do |w|
		where << glue
		case w
			when /^F(\d+)$/i   # F2100 = peak frequency between 2095hz and 2105hz
				freq = $1.to_i
				where << "( peak_freq > ? AND peak_freq < ? ) "
				param << freq - 5.0
				param << freq + 5.0
			else
				where << "( number ILIKE ? OR caller_id ILIKE ? OR line_type ILIKE ? ) "
				param << "%#{w}%"
				param << "%#{w}%"
				param << "%#{w}%"
		end
		glue = "AND " if glue.empty?
		@search_conditions = [ where, *param ]
	end
  end


end
