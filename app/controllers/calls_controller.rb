class CallsController < ApplicationController

  # GET /calls
  # GET /calls.xml
  def index
    @jobs = Job.where(:status => 'answered').paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30

	)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @calls }
    end
  end

  # GET /calls/1/reanalyze
  def reanalyze
  	Call.update_all(['processed = ?', false], ['job_id = ?', params[:id]])
	j = Job.find(params[:id])
	j.processed = false
	j.save

	redirect_to :action => 'analyze'
  end

  # GET /calls/1/process
  # GET /calls/1/process.xml
  def analyze
  	@job_id = params[:id]
	@job    = Job.find(@job_id)

	if(@job.processed)
		redirect_to :controller => 'analyze', :action => 'view', :id => @job_id
		return
	end

	@dial_data_total = Call.count(
		:conditions => [ 'job_id = ? and answered = ?', @job_id, true ]
	)

	@dial_data_done = Call.count(
		:conditions => [ 'job_id = ? and processed = ?', @job_id, true ]
	)

	ltypes = Call.find( :all, :select => 'DISTINCT line_type', :conditions => ["job_id = ?", @job_id] ).map{|r| r.line_type}
	res_types = {}

	ltypes.each do |k|
		next if not k
		res_types[k.capitalize.to_sym] = Call.count(
			:conditions => ['job_id = ? and line_type = ?', @job_id, k]
		)
	end

	@lines_by_type = res_types

	@dial_data_todo = Call.where(:job_id => @job_id).paginate(
		:page => params[:page],
		:order => 'number ASC',
		:per_page => 50,
		:conditions => [ 'answered = ? and processed = ? and busy = ?', true, false, false ]
	)

	if @dial_data_todo.length > 0
        res = @job.schedule(:analysis)
		unless res
			flash[:error] = "Unable to launch analysis job"
		end
	end
  end

  # GET /calls/1/view
  # GET /calls/1/view.xml
  def view
    @calls = Call.where(:job_id => params[:id]).paginate(
		:page => params[:page],
		:order => 'number ASC',
		:per_page => 30
	)

	unless @calls and @calls.length > 0
		redirect_to :action => :index
		return
	end
	@call_results = {
		:Timeout  => Call.count(:conditions =>['job_id = ? and answered = ?', params[:id], false]),
		:Busy     => Call.count(:conditions =>['job_id = ? and busy = ?', params[:id], true]),
		:Answered => Call.count(:conditions =>['job_id = ? and answered = ?', params[:id], true]),
	}

	respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @calls }
    end
  end

  # GET /calls/1
  # GET /calls/1.xml
  def show
    @call = Call.find(params[:id])

	unless @call
		redirect_to :action => :index
		return
	end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @call }
    end
  end

  # GET /calls/new
  # GET /calls/new.xml
  def new
    @call = Call.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @call }
    end
  end

  # GET /calls/1/edit
  def edit
    @call = Call.find(params[:id])
  end

  # POST /calls
  # POST /calls.xml
  def create
    @call = Call.new(params[:call])

    respond_to do |format|
      if @call.save
        flash[:notice] = 'Call was successfully created.'
        format.html { redirect_to(@call) }
        format.xml  { render :xml => @call, :status => :created, :location => @call }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @call.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /calls/1
  # PUT /calls/1.xml
  def update
    @call = Call.find(params[:id])

    respond_to do |format|
      if @call.update_attributes(params[:call])
        flash[:notice] = 'Call was successfully updated.'
        format.html { redirect_to(@call) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @call.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /calls/1
  # DELETE /calls/1.xml
  def destroy

    @job = Job.find(params[:id])
	@job.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end

end
