class JobsController < ApplicationController

  def index
  	@submitted_jobs = Job.where(:status => ['submitted', 'scheduled'], :completed_at => nil)
	@active_jobs    = Job.where(:status => 'running', :completed_at => nil)
	@inactive_jobs = Job.where('status NOT IN (?) OR completed_at IS NULL', ['submitted', 'scheduled', 'running']).paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30
	)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @active_jobs + @submitted_jobs }
    end
  end


  def new_dialer
    @job = Job.new
    if @project
    	@job.project = @project
    else
    	@job.project = Project.last
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  def dialer
    @job = Job.new(params[:job])
    @job.created_by = current_user.login
    @job.task = 'dialer'
	@job.range.gsub!(/[^0-9X:,\n]/, '')
	@job.cid_mask.gsub!(/[^0-9X]/, '') if @job.cid_mask != "SELF"

	if @job.range_file.to_s != ""
		@job.range = @job.range_file.read.gsub(/[^0-9X:,\n]/, '')
	end

    respond_to do |format|
      if @job.schedule
        flash[:notice] = 'Job was successfully created.'
	    format.html { redirect_to :action => :index }
        format.xml  { render :xml => @job, :status => :created }
      else
        format.html { render :action => "new_dialer" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def stop
    @job = Job.find(params[:id])
	@job.stop
	flash[:notice] = "Job has been cancelled"
    redirect_to :action => 'index'
  end

  def create

	@job = Job.new(params[:job])

    if(Provider.find_all_by_enabled(true).length == 0)
		@job.errors.add(:base, "No providers have been configured or enabled, this job cannot be run")
		respond_to do |format|
			format.html { render :action => "new" }
			format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
		end
		return
	end

	@job.status       = 'submitted'
	@job.progress     = 0
	@job.started_at   = nil
	@job.completed_at = nil
	@job.range        = @job_range.gsub(/[^0-9X:,\n]/m, '')
	@job.cid_mask     = @cid_mask.gsub(/[^0-9X]/m, '') if @job.cid_mask != "SELF"

	if(@job.range_file.to_s != "")
		@job.range = @job.range_file.read.gsub(/[^0-9X:,\n]/m, '')
	end

    respond_to do |format|
      if @job.save
        flash[:notice] = 'Job was successfully created.'

		res = @job.schedule(:dialer)
		unless res
			flash[:error] = "Unable to launch dialer job"
		end

	    format.html { redirect_to :action => 'index' }
        format.xml  { render :xml => @job, :status => :created, :location => @job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
    end
  end

end
