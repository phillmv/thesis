class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
    @user = User.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user = User.new
    if @user_session.save
      redirect_to '/'
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to '/'
  end
end  
