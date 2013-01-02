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
  	@job = Job.find(@job_id)
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

	if(@shown and @shown != 'all')
		@results = Call.where(:job_id => @job_id).paginate(
			:page => params[:page],
			:order => 'number ASC',
			:per_page => 10,
			:conditions => [ 'completed = ? and processed = ? and busy = ? and line_type = ?', true, true, false, @shown ]
		)
	else
		@results = Call.where(:job_id => @job_id).paginate(
			:page => params[:page],
			:order => 'number ASC',
			:per_page => 10,
			:conditions => [ 'completed = ? and processed = ? and busy = ?', true, true, false ]
		)
	end

	@filters = []
	@filters << { :scope => "all", :label => "All" }
	res_types.keys.each do |t|
		@filters << { :scope => t.to_s.downcase, :label => t.to_s }
	end

  end

 def show
  	@job_id   = params[:id]
  	@job = Job.find(@job_id)
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

	if(@shown and @shown != 'all')
		@results = Job.where(:id => @job_id).paginate(
			:page => params[:page],
			:order => 'number ASC',
			:per_page => 20,
			:conditions => [ 'completed = ? and processed = ? and busy = ? and line_type = ?', true, true, false, @shown ]
		)
	else
		@results = Job.where(:id => @job_id).paginate(
			:page => params[:page],
			:order => 'number ASC',
			:per_page => 20,
			:conditions => [ 'completed = ? and processed = ? and busy = ?', true, true, false ]
		)
	end

	@filters = []
	@filters << { :scope => "all", :label => "All" }
	res_types.keys.each do |t|
		@filters << { :scope => t.to_s.downcase, :label => t.to_s }
	end

  end


  # GET /calls/1/resource?id=XXX&type=YYY
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


  def view_matches
  	@result = Call.find(params[:call_id])
  	@job_id = @result.job_id
	@results = @result.matches.select{|x| x.matchscore.to_f > 10.0 }
  end
end
