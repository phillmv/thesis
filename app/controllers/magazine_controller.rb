class MagazineController < ApplicationController

  def index
    Stream.prune(@current_user)
    @stream = Stream.page(@current_user.id, 10, params[:page])
    respond_to do |format|
      format.html
      format.js { render "index.haml", layout => false }
    end
  end

  def more
    @stream = Stream.page(@current_user.id, 10, params[:page])
  
    render :partial => "shared/entries", :locals => { :stream => @stream }
  end

  def nothing
    render :text => ""
  end

  def read
    @current_user.read!(Entry.find(params[:id]))

    render :text => "OK"
  end
end
