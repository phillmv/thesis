class MagazineController < ApplicationController

  def index
    Stream.prune(@current_user)
    @stream = Stream.page(@current_user.id, 10, params[:page])
    respond_to do |format|
      format.html
    end
  end

  def more
    @stream = Stream.page(@current_user.id, 10, params[:page])
    respond_to do |format|
      format.html { render "index", :layout => false }
    end
  end

  def nothing
    render :text => ""
  end

  def read
    @current_user.read!(Entry.find(params[:id]))

    render :text => "OK"
  end
end
