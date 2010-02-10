class RenameFeedsToSubscriptions < ActiveRecord::Migration
  def self.up
    rename_table :feeds, :subscriptions
  end

  def self.down
    oh_noes
  end
end
