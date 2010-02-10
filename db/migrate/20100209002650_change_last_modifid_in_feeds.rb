class ChangeLastModifidInFeeds < ActiveRecord::Migration
  def self.up
    change_column :feeds, :last_modified, :datetime
  end

  def self.down
    oh_noes
  end
end
