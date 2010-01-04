class MagazineController < ApplicationController

  def index
    @entries = Entry.find(:all, :order => "published DESC", :limit => 30)
  end
end
