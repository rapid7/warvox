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

  def results

    @jobs = @project.jobs.where('(task = ? OR task = ?) AND completed_at IS NOT NULL', 'dialer', 'import').paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30
	)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @calls }
    end
  end

  def view_results
  	@job   = Job.find(params[:id])
  	@calls = @job.calls.paginate(
		:page => params[:page],
		:order => 'id DESC',
		:per_page => 30
	)
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

  def reanalyze_job
	@job = Job.find(params[:id])
	@new = Job.new({
		:task => 'analysis', :scope => 'job', :target_id => @job.id, :force => true,
		:project_id => @project.id, :status => 'submitted'
	})
    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Analysis job was successfully created.'
	    format.html { redirect_to jobs_path }
        format.xml  { render :xml => @job, :status => :created }
      else
      	flash[:notice] = 'Analysis job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  def analyze_job
	@job = Job.find(params[:id])
	@new = Job.new({
		:task => 'analysis', :scope => 'job', :target_id => @job.id,
		:project_id => @project.id, :status => 'submitted'
	})
    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Analysis job was successfully created.'
	    format.html { redirect_to jobs_path }
        format.xml  { render :xml => @job, :status => :created }
      else
      	flash[:notice] = 'Analysis job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
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

  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
    end
  end

end
