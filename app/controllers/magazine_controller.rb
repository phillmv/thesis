class MagazineController < ApplicationController

  def index
    @stream = Stream.page(@current_user.id, 3, params[:page])
    respond_to do |format|
      format.html
      format.js { render "index.haml", layout => false }
    end
  end

  def more
    @stream = Stream.page(@current_user.id, 3, params[:page])

    render :index, :layout => false
  end

  def nothing
    render :text => ""
  end

  def read
    @current_user.read!(Entry.find(params[:id]))

    render :text => "OK"
  end
end
