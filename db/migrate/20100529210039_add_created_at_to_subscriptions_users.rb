class AddCreatedAtToSubscriptionsUsers < ActiveRecord::Migration
  def self.up
    add_column :subscriptions_users, :created_at, :datetime
  end

  def self.down
    remove_column :subscriptions_users, :created_at
  end
end
