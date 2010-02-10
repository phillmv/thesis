class MagazineController < ApplicationController

  def index
    @entries = Entry.find(:all, :order => "published DESC", :limit => 60)
  end
end
