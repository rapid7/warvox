class DialResultsController < ApplicationController
  layout 'warvox'
  
  # GET /dial_results
  # GET /dial_results.xml
  def index
    @completed_jobs = DialJob.paginate_all_by_status(
		'completed', 
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
  	DialResult.find_all_by_dial_job_id(params[:id]).each do |r|
		r.processed    = false
		r.processed_at = 0
		r.save
	end
	j = DialJob.find_by_id(params[:id])
	j.processed = false
	j.save
	
	redirect_to :action => 'analyze'
  end
  
  # GET /dial_results/1/process
  # GET /dial_results/1/process.xml  
  def analyze
  	@job_id = params[:id]
	@job    = DialJob.find(@job_id)

	@dial_data_total = DialResult.find_all_by_dial_job_id(
		@job_id,
		:conditions => [ 'completed = ? and busy = ?', true, false ]
	).length
	
	@dial_data_done_set = DialResult.find_all_by_dial_job_id(
		@job_id,
		:conditions => [ 'processed = ?', true]
	)
	@dial_data_done = @dial_data_done_set.length

	@g1 = Ezgraphix::Graphic.new(:c_type => 'col3d', :div_name => 'calls_pie1')
	@g1.render_options(:caption => 'Detected Lines by Type', :y_name => 'Lines')
	
	@g2 = Ezgraphix::Graphic.new(:c_type => 'pie2d', :div_name => 'calls_pie2')
	@g2.render_options(:caption => 'Analysis Progress')
			
	res_types = {}
	@dial_data_done_set.each do |r|
		res_types[ r.line_type.capitalize.to_sym ] ||= 0
		res_types[ r.line_type.capitalize.to_sym ]  += 1		
	end
	
	@g1.data = res_types
	@g2.data = {:Remaining => @dial_data_total-@dial_data_done, :Complete => @dial_data_done}		
	
	@dial_data_todo = DialResult.paginate_all_by_dial_job_id(
		@job_id,
		:page => params[:page], 
		:order => 'number ASC',
		:per_page => 50,
		:conditions => [ 'completed = ? and processed = ? and busy = ?', true, false, false ]
	)

	if(@job.processed)
		redirect_to :controller => 'analyze', :action => 'view', :id => @job_id
		return
	end
	
	if(@dial_data_todo.length > 0)
        WarVOX::JobManager.schedule(::WarVOX::Jobs::Analysis, @job_id)
	end
  end

  # GET /dial_results/1/view
  # GET /dial_results/1/view.xml
  def view
    @dial_results = DialResult.paginate_all_by_dial_job_id(
		params[:id],
		:page => params[:page], 
		:order => 'number ASC',
		:per_page => 30
	)		
	
	if(@dial_results)
		@g1 = Ezgraphix::Graphic.new(:c_type => 'pie2d', :div_name => 'calls_pie1')
		@g1.render_options(:caption => 'Call Results')
		
		@g2 = Ezgraphix::Graphic.new(:c_type => 'pie2d', :div_name => 'calls_pie2')
		@g2.render_options(:caption => 'Call Length')
		
		res = {
			:Timeout  => 0,
			:Busy     => 0,
			:Answered => 0
		}
		sec = {}
		
		@dial_results.each do |r|		
			sec[r.seconds] ||= 0
			sec[r.seconds]  += 1
			
			if(not r.completed)
				res[:Timeout] += 1
				next
			end
			if(r.busy)
				res[:Busy] += 1
				next
			end
			res[:Answered] += 1
		end
		
		@g1.data = res
		@g2.data = sec
	end
	

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @dial_results }
    end
  end
  
  # GET /dial_results/1
  # GET /dial_results/1.xml
  def show
    @dial_result = DialResult.find(params[:id])

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
  def purge
  
    @job = DialJob.find(params[:id])
	@job.dial_results.each do |r|
		r.destroy
	end
	@job.destroy
	
	dir = nil
	jid = @job.id
	dfd = Dir.new(WarVOX::Config.data_path)
	dfd.entries.each do |ent|
		j,m = ent.split('-', 2)
		if (m and j == jid)
			dir = File.join(WarVOX::Config.data_path, ent)
		end
	end
	
	FileUtils.rm_rf(dir) if dir

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end
  
  # DELETE /dial_results/1
  # DELETE /dial_results/1.xml
  def delete
    @res = DialResult.find(params[:id])
	@res.destroy
    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end  
end
