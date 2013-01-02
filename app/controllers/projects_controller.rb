class ProjectsController < ApplicationController

	def index
   		@projects = Project.paginate(
			:page => params[:page],
			:order => 'id DESC',
			:per_page => 10
		)

		@new_project = Project.new

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @projects }
		end
	end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    @new_project = Project.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @new_project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # POST /projects
  # POST /projects.xml
  def create
    @new_project = Project.new(params[:project])
    @new_project.created_by = current_user.login

    respond_to do |format|
      if @new_project.save
        flash[:notice] = 'Project was successfully created.'
        format.html { redirect_to(project_path(@new_project)) }
        format.xml  { render :xml => @project, :status => :created, :location => @new_project }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @new_project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to projects_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
  end


end
