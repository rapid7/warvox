class DialJobsController < ApplicationController
  layout 'warvox'
  
  # GET /dial_jobs
  # GET /dial_jobs.xml
  def index
  	@submitted_jobs = DialJob.find_all_by_status('submitted')
    @active_jobs    = DialJob.find_all_by_status('active')
	@new_job        = DialJob.new
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @active_jobs + @submitted_jobs }
    end
  end

  # GET /dial_jobs/new
  # GET /dial_jobs/new.xml
  def new
    @dial_job = DialJob.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @dial_job }
    end
  end

  # GET /dial_jobs/1/edit
  def edit
    @dial_job = DialJob.find(params[:id])
  end

  # GET /dial_jobs/1/run
  def run
    @dial_job = DialJob.find(params[:id])
	
	if(@dial_job.status != 'submitted')
	  flash[:notice] = 'Job is already running or completed'
	  return
	end
	
	dialer = WarVOX::Jobs::Dialer.new(@dial_job.id)
	WarVOX::JobManager.schedule(dialer)
	redirect_to :action => 'index'
  end
  
  def stop
    @dial_job = DialJob.find(params[:id])
	
	if(@dial_job.status != 'submitted')
	  flash[:notice] = 'Job is already running or completed'
	  return
	end 
  end
  
  
  # POST /dial_jobs
  # POST /dial_jobs.xml
  def create
  	
	@dial_job = DialJob.new(params[:dial_job])
  
    if(Provider.find_all_by_enabled(true).length == 0)
		@dial_job.errors.add("No providers have been configured or enabled, this job ")
		respond_to do |format|
			format.html { render :action => "new" }
			format.xml  { render :xml => @dial_job.errors, :status => :unprocessable_entity }
		end
		return
	end

	@dial_job.status       = 'submitted'
	@dial_job.progress     = 0
	@dial_job.started_at   = nil
	@dial_job.completed_at = nil
	@dial_job.range.gsub!(/[^0-9X]/, '')
	@dial_job.cid_mask.gsub!(/[^0-9X]/, '') if @dial_job.cid_mask != "SELF"

    respond_to do |format|
      if @dial_job.save
        flash[:notice] = 'Job was successfully created.'
        
        # Launch it	
        dialer = WarVOX::Jobs::Dialer.new(@dial_job.id)
        WarVOX::JobManager.schedule(dialer)
	
        format.html { redirect_to(@dial_job) }
        format.xml  { render :xml => @dial_job, :status => :created, :location => @dial_job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @dial_job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /dial_jobs/1
  # DELETE /dial_jobs/1.xml
  def destroy
    @dial_job = DialJob.find(params[:id])
    @dial_job.destroy

    respond_to do |format|
      format.html { redirect_to(dial_jobs_url) }
      format.xml  { head :ok }
    end
  end
  
  # GET /dial_jobs/1
  # GET /dial_jobs/1.xml
  def show
    @dial_job = DialJob.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dial_job }
    end
  end
    
  # PUT /dial_jobs/1
  # PUT /dial_jobs/1.xml
  def update
    @dial_job = DialJob.find(params[:id])
    respond_to do |format|
      if @dial_job.update_attributes(params[:dial_job])
        flash[:notice] = 'Job was successfully updated.'
        format.html { redirect_to(@dial_job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dial_job.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end
