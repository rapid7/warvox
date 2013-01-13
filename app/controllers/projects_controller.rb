class ProjectsController < ApplicationController

	def index
	 	@projects = Project.paginate(
			:page => params[:page],
			:order => 'id DESC',
			:per_page => 10
		)

		@new_project = Project.new

		respond_to do |format|
			format.html
			format.xml	{ render :xml => @projects }
		end
	end

	def show
		@project = Project.find(params[:id])
		@active_jobs = @project.jobs.where(:status => 'running', :completed_at => nil)
		@inactive_jobs	= @project.jobs.where('status NOT IN (?)', ['submitted', 'scheduled', 'running']).paginate(
			:page => params[:page],
			:order => 'id DESC',
			:per_page => 30
		)

		@boxes = {
			:called    => { :cnt => @project.calls.count },
			:answered  => { :cnt => @project.calls.where(:answered => true).count },
			:analyzed  => { :cnt => @project.calls.where('analysis_completed_at IS NOT NULL').count },
			:voice     => { :cnt => @project.lines.where(:line_type => 'voice').count },
			:voicemail => { :cnt => @project.lines.where(:line_type => 'voicemail').count },
			:fax       => { :cnt => @project.lines.where(:line_type => 'fax').count },
			:modem     => { :cnt => @project.lines.where(:line_type => 'modem').count }
		}

		if @boxes[:called][:cnt] == 0
			@boxes[:called][:txt] = '0'
			@boxes[:called][:cls] = 'nodata'

			# No calls, so everything else is unknown
			[ :answered, :analyzed, :voice, :voicemail, :fax, :modem ].each do |t|
				@boxes[t][:txt] = '?'
				@boxes[t][:cls] = 'nodata'
			end

		else

			[ :called, :answered, :analyzed].each do |t|
				@boxes[t][:txt] = number_with_delimiter(@boxes[t][:cnt])
				@boxes[t][:cls] = 'completed'
			end

			if @boxes[:answered][:cnt] == 0
				@boxes[:answered][:txt] = '0'
				@boxes[:answered][:cls] = 'nodata'
			end

			if @boxes[:analyzed][:cnt] == 0
				[ :voice, :voicemail, :fax, :modem ].each do |t|
					@boxes[t][:txt] = '?'
					@boxes[t][:cls] = 'nodata'
				end
				@boxes[:analyzed][:cls] = 'nodata'
			else

				@boxes[:voice][:txt] = number_with_delimiter(@boxes[:voice][:cnt])
				@boxes[:voice][:cls] = 'voice'

				@boxes[:voicemail][:txt] = number_with_delimiter(@boxes[:voicemail][:cnt])
				@boxes[:voicemail][:cls] = 'voicemail'

				@boxes[:fax][:txt] = number_with_delimiter(@boxes[:fax][:cnt])
				@boxes[:fax][:cls] = 'fax'

				@boxes[:modem][:txt] = number_with_delimiter(@boxes[:modem][:cnt])
				@boxes[:modem][:cls] = 'modem'
			end
		end

		respond_to do |format|
			format.html
			format.xml	{ render :xml => @project }
		end
	end

	def new
		@new_project = Project.new
		respond_to do |format|
			format.html
			format.xml	{ render :xml => @new_project }
		end
	end


	def edit
		@project = Project.find(params[:id])
	end

	def create
		@new_project = Project.new(params[:project])
		@new_project.created_by = current_user.login

		respond_to do |format|
			if @new_project.save
				format.html { redirect_to(project_path(@new_project)) }
				format.xml	{ render :xml => @project, :status => :created, :location => @new_project }
			else
				format.html { render :action => "new" }
				format.xml	{ render :xml => @new_project.errors, :status => :unprocessable_entity }
			end
		end
	end

	def update
		@project = Project.find(params[:id])

		respond_to do |format|
			if @project.update_attributes(params[:project])
				format.html { redirect_to projects_path }
				format.xml	{ head :ok }
			else
				format.html { render :action => "edit" }
				format.xml	{ render :xml => @project.errors, :status => :unprocessable_entity }
			end
		end
	end

	def destroy
		@project = Project.find(params[:id])
		@project.destroy

		respond_to do |format|
			format.html { redirect_to(projects_url) }
			format.xml	{ head :ok }
		end
	end
end
