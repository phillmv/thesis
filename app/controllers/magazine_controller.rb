class MagazineController < ApplicationController

  def index
    @stream = Stream.paginate_by_sql("select stream.*, entries.published from stream inner join entries on stream.entry_id = entries.id order by published DESC", :per_page => 10, :page => params[:page])
  end

  def more
    @stream = Stream.paginate_by_sql("select stream.*, entries.published from stream inner join entries on stream.entry_id = entries.id order by published DESC", :per_page => 10, :page => params[:page])


    render :index, :layout => false
  end

  def read
    @entry = Entry.find(params[:id])
    @entry.read!

    render :text => "OK"
  end
end
