class RemoveFeedUrlFromEntries < ActiveRecord::Migration
  def self.up
    remove_column :entries, :feed_url
  end

  def self.down
    oh_noes
  end
end
