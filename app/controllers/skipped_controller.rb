class SkippedController < ApplicationController
  def index
    @entries = Entry.paginate_by_sql(["select * from entries e where e.id in (select m.entry_id from metadata m where m.user_id = ? and m.read = ?) order by e.published desc", @current_user.id, Metadata::SKIPPED], { :per_page => 10, :page => params[:page] })
  end

end
