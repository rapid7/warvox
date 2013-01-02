class ApplicationController < ActionController::Base
	helper :all
	protect_from_forgery
	helper_method :current_user_session, :current_user
	before_filter :require_user, :load_project
	add_breadcrumb :projects, :root_path

private

	def current_user_session
		return @current_user_session if defined?(@current_user_session)
		@current_user_session = UserSession.find
	end

	def current_user
		return @current_user if defined?(@current_user)
		@current_user = current_user_session && current_user_session.record
	end

	def require_user
		unless current_user
			store_location
			flash[:notice] = "You must be logged in to access this page"
			redirect_to '/login'
			return false
		end
	end

	def require_no_user
		if current_user
			store_location
			flash[:notice] = "You must be logged out to access this page"
			redirect_to user_path(current_user)
			return false
		end
	end

	def store_location
		session[:return_to] = request.fullpath
	end

	def redirect_back_or_default(default)
		redirect_to(session[:return_to] || default)
		session[:return_to] = nil
	end

	def load_project
		# Only load this when we are logged in
		return true unless current_user

		if params[:project_id]
			@project = Project.where(:id => params[:project_id].to_i).first
		elsif session[:project_id]
			@project = Project.where(:id => session[:project_id].to_i).first
		end

		if @project and @project.id and not (session[:project_id] and session[:project_id] == @project.id)
			session[:project_id] = @project.id
		end

		true
	end


end
