class MagazineController < ApplicationController

  def index
    @entries = Entry.paginate(:page => params[:page],
                              :per_page => 10,
                              :order => "published DESC",
                              :conditions => { :read => nil })
  end

  def more
    @entries = Entry.paginate(:page => params[:page],
                              :per_page => 10,
                              :order => "published DESC",
                              :conditions => { :read => nil })

    render :index, :layout => false
  end

  def read
    @entry = Entry.find(params[:id])
    @entry.read!

    render :text => "OK"
  end
end
