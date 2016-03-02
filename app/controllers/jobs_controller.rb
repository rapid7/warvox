class JobsController < ApplicationController

  require 'shellwords'

  def index
    @reload_interval = 20000

    @submitted_jobs = Job.where(:status => ['submitted', 'scheduled'], :completed_at => nil)
    @active_jobs    = Job.where(:status => 'running', :completed_at => nil)
    @inactive_jobs  = Job.order('id DESC').where('status NOT IN (?)', ['submitted', 'scheduled', 'running']).paginate(
      :page => params[:page],
      :per_page => 30
    )

    if @active_jobs.length > 0
      @reload_interval = 5000
    end

    if @submitted_jobs.length > 0
      @reload_interval = 3000
    end

    respond_to do |format|
      format.html
    end
  end

  def results
    @jobs = @project.jobs.order('id DESC').where('(task = ? OR task = ?) AND completed_at IS NOT NULL', 'dialer', 'import').paginate(
      :page => params[:page],
      :per_page => 30
    )

    respond_to do |format|
      format.html
    end
  end

  def view_results
    @job = Job.find(params[:id])

    @call_results = {
      :Timeout  => @job.calls.count(:conditions => { :answered => false }),
      :Busy     => @job.calls.count(:conditions => { :busy     => true }),
      :Answered => @job.calls.count(:conditions => { :answered => true }),
    }

    sort_by   = params[:sort_by] || 'number'
    sort_dir = params[:sort_dir] || 'asc'

    @results = []
    @results_total_count = @job.calls.count()

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
        render :content_type => 'application/json', :json => render_to_string(:partial => 'view_results', :results => @results, :call_results => @call_results )
      }
    end
  end

  # Generate a SQL sort by option based on the incoming DataTables paramater.
  #
  # Returns the SQL String.
  def calls_sort_option
    column = case params[:iSortCol_0].to_s
      when '1'
        'number'
      when '2'
        'caller_id'
      when '3'
        'providers.name'
      when '4'
        'answered'
      when '5'
        'busy'
      when '6'
        'audio_length'
      when '7'
        'ring_length'
    end
    column + ' ' + (params[:sSortDir_0] =~ /^A/i ? 'asc' : 'desc') if column
  end

  def calls_search
    @search_conditions = []
    terms = params[:sSearch].to_s
    terms = Shellword.shellwords(terms) rescue terms.split(/\s+/)
    where = ""
    param = []
    glue  = ""
    terms.each do |w|
      next if w.downcase == 'undefined'
      where << glue
      case w
        when 'answered'
          where << "answered = ? "
          param << true
        when 'busy'
          where << "busy = ? "
          param << true
        else
          where << "( number ILIKE ? OR caller_id ILIKE ? ) "
          param << "%#{w}%"
          param << "%#{w}%"
      end
      glue = "AND " if glue.empty?
      @search_conditions = [ where, *param ]
    end
  end

  def new_dialer
    @job = Job.new
    if @project
      @job.project = @project
    else
      @job.project = Project.last
    end

    if params[:result_ids]
      nums = ""
      Call.find_each(:conditions => { :id => params[:result_ids] }) do |call|
        nums << call.number + "\n"
      end
      @job.range = nums
    end

    respond_to do |format|
      format.html
     end
  end

  def purge_calls
    Call.delete_all(:id => params[:result_ids])
    CallMedium.delete_all(:call_id => params[:result_ids])
    flash[:notice] = "Purged #{params[:result_ids].length} calls"
    if params[:id]
      @job = Job.find(params[:id])
      redirect_to view_results_path(@job.project_id, @job.id)
    else
      redirect_to analyze_path(@project)
    end
  end

  def dialer
    @job = Job.new(params[:job])
    @job.created_by = @current_user.login
    @job.task = 'dialer'
    @job.range.to_s.gsub!(/[^0-9X:,\n]/, '')
    @job.cid_mask.to_s.gsub!(/[^0-9X]/, '') if @job.cid_mask != "SELF"

    if @job.range_file.to_s != ""
      @job.range = @job.range_file.read.gsub(/[^0-9X:,\n]/, '')
    end

    respond_to do |format|
      if @job.schedule
        flash[:notice] = 'Job was successfully created.'
        format.html { redirect_to :action => :index }
      else
        format.html { render :action => "new_dialer" }
      end
    end
  end

  def new_analyze
    @job = Job.new
    if @project
      @job.project = @project
    else
      @job.project = Project.last
    end

    if params[:result_ids]
      nums = ""
      Call.find_each(:conditions => { :id => params[:result_ids] }) do |call|
        nums << call.number + "\n"
      end
      @job.range = nums
    end

    respond_to do |format|
      format.html
     end
  end

  def new_identify
    @job = Job.new
    if @project
      @job.project = @project
    else
      @job.project = Project.last
    end

    if params[:result_ids]
      nums = ""
      Call.find_each(:conditions => { :id => params[:result_ids] }) do |call|
        nums << call.number + "\n"
      end
      @job.range = nums
    end

    respond_to do |format|
      format.html
     end
  end

  def reanalyze_job
    @job = Job.find(params[:id])
    @new = Job.new({
      :task => 'analysis', :scope => 'job', :target_id => @job.id, :force => true,
      :project_id => @project.id, :status => 'submitted'
    })
    @new.created_by = @current_user.login
    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Analysis job was successfully created.'
        format.html { redirect_to jobs_path }
      else
        flash[:notice] = 'Analysis job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
      end
    end
  end

  def analyze_job
    @job = Job.find(params[:id])

    # Handle analysis of specific call IDs via checkbox submission
    if params[:result_ids]
      @new = Job.new({
        :task => 'analysis', :scope => 'calls', :target_ids => params[:result_ids],
        :project_id => @project.id, :status => 'submitted'
      })
    else
    # Otherwise analyze the entire Job
      @new = Job.new({
        :task => 'analysis', :scope => 'job', :target_id => @job.id,
        :project_id => @project.id, :status => 'submitted'
      })
    end

    @new.created_by = @current_user.login

    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Analysis job was successfully created.'
        format.html { redirect_to jobs_path }
      else
        flash[:notice] = 'Analysis job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
      end
    end
  end


  def analyze_project

    # Handle analysis of specific call IDs via checkbox submission
    if params[:result_ids]
      @new = Job.new({
        :task => 'analysis', :scope => 'calls', :target_ids => params[:result_ids],
        :project_id => @project.id, :status => 'submitted'
      })
    else
    # Otherwise analyze the entire Project
      @new = Job.new({
        :task => 'analysis', :scope => 'project', :target_id => @project.id,
        :project_id => @project.id, :status => 'submitted'
      })
    end

    @new.created_by = @current_user.login

    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Analysis job was successfully created.'
        format.html { redirect_to jobs_path }
      else
        flash[:notice] = 'Analysis job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
      end
    end
  end

  def identify_job
    @job = Job.find(params[:id])

    # Handle identification of specific lines via checkbox submission
    if params[:result_ids]
      @new = Job.new({
        :task => 'identify', :scope => 'calls', :target_ids => params[:result_ids],
        :project_id => @project.id, :status => 'submitted'
      })
    else
    # Otherwise analyze the entire Job
      @new = Job.new({
        :task => 'identify', :scope => 'job', :target_id => @job.id,
        :project_id => @project.id, :status => 'submitted'
      })
    end

    @new.created_by = @current_user.login

    respond_to do |format|
      if @new.schedule
        flash[:notice] = 'Identify job was successfully created.'
        format.html { redirect_to jobs_path }
      else
        flash[:notice] = 'Identify job could not run: ' + @new.errors.inspect
        format.html { redirect_to results_path(@project) }
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
