class RenameEntriesFeedIdToSubscriptionId < ActiveRecord::Migration
  def self.up
    rename_column :entries, :feed_id, :subscription_id
  end

  def self.down
    oh_noes
  end
end
