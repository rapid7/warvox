class DialResultsController < ApplicationController

  # GET /dial_results
  # GET /dial_results.xml
  def index
    @jobs = DialJob.where(:status => 'completed').paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30

	)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @dial_results }
    end
  end

  # GET /dial_results/1/reanalyze
  def reanalyze
  	DialResult.update_all(['processed = ?', false], ['dial_job_id = ?', params[:id]])
	j = DialJob.find(params[:id])
	j.processed = false
	j.save

	redirect_to :action => 'analyze'
  end

  # GET /dial_results/1/process
  # GET /dial_results/1/process.xml
  def analyze
  	@job_id = params[:id]
	@job    = DialJob.find(@job_id)

	if(@job.processed)
		redirect_to :controller => 'analyze', :action => 'view', :id => @job_id
		return
	end

	@dial_data_total = DialResult.count(
		:conditions => [ 'dial_job_id = ? and completed = ?', @job_id, true ]
	)

	@dial_data_done = DialResult.count(
		:conditions => [ 'dial_job_id = ? and processed = ?', @job_id, true ]
	)

	ltypes = DialResult.find( :all, :select => 'DISTINCT line_type', :conditions => ["dial_job_id = ?", @job_id] ).map{|r| r.line_type}
	res_types = {}

	ltypes.each do |k|
		next if not k
		res_types[k.capitalize.to_sym] = DialResult.count(
			:conditions => ['dial_job_id = ? and line_type = ?', @job_id, k]
		)
	end

	@lines_by_type = res_types

	@dial_data_todo = DialResult.where(:dial_job_id => @job_id).paginate(
		:page => params[:page],
		:order => 'number ASC',
		:per_page => 50,
		:conditions => [ 'completed = ? and processed = ? and busy = ?', true, false, false ]
	)

	if(@dial_data_todo.length > 0)
        WarVOX::JobManager.schedule(::WarVOX::Jobs::Analysis, @job_id)
	end
  end

  # GET /dial_results/1/view
  # GET /dial_results/1/view.xml
  def view
    @dial_results = DialResult.where(:dial_job_id => params[:id]).paginate(
		:page => params[:page],
		:order => 'number ASC',
		:per_page => 30
	)

	unless @dial_results and @dial_results.length > 0
		redirect_to :action => :index
		return
	end
	@call_results = {
		:Timeout  => DialResult.count(:conditions =>['dial_job_id = ? and completed = ?', params[:id], false]),
		:Busy     => DialResult.count(:conditions =>['dial_job_id = ? and busy = ?', params[:id], true]),
		:Answered => DialResult.count(:conditions =>['dial_job_id = ? and completed = ?', params[:id], true]),
	}

	respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @dial_results }
    end
  end

  # GET /dial_results/1
  # GET /dial_results/1.xml
  def show
    @dial_result = DialResult.find(params[:id])

	unless @dial_result
		redirect_to :action => :index
		return
	end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dial_result }
    end
  end

  # GET /dial_results/new
  # GET /dial_results/new.xml
  def new
    @dial_result = DialResult.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @dial_result }
    end
  end

  # GET /dial_results/1/edit
  def edit
    @dial_result = DialResult.find(params[:id])
  end

  # POST /dial_results
  # POST /dial_results.xml
  def create
    @dial_result = DialResult.new(params[:dial_result])

    respond_to do |format|
      if @dial_result.save
        flash[:notice] = 'DialResult was successfully created.'
        format.html { redirect_to(@dial_result) }
        format.xml  { render :xml => @dial_result, :status => :created, :location => @dial_result }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @dial_result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /dial_results/1
  # PUT /dial_results/1.xml
  def update
    @dial_result = DialResult.find(params[:id])

    respond_to do |format|
      if @dial_result.update_attributes(params[:dial_result])
        flash[:notice] = 'DialResult was successfully updated.'
        format.html { redirect_to(@dial_result) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dial_result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /dial_results/1
  # DELETE /dial_results/1.xml
  def destroy

    @job = DialJob.find(params[:id])
	@job.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end

end
