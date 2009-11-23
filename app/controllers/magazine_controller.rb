class MagazineController < ApplicationController

  def index
    @entries = Entry.shuffled
  end
end
