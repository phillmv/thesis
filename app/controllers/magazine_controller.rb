class MagazineController < ApplicationController

  def index
    @stream = Stream.page(@current_user.id, 10, params[:page])
  end

  def more
    @stream = Stream.page(@current_user.id, 10, params[:page])

    render :index, :layout => false
  end

  def read
    @current_user.read!(Entry.find(params[:id]))

    render :text => "OK"
  end
end
