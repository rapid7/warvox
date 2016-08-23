class UserSessionsController < ApplicationController
  before_action :require_no_user, :only => [:new, :create]
  before_action :require_user, :only => :destroy
  layout 'login'

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(user_session_params)
    if @user_session.save
      redirect_back_or_default projects_path
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    redirect_back_or_default login_path
  end

  private

  def user_session_params
    params.require(:user_session).permit(:login, :password)
  end
end
