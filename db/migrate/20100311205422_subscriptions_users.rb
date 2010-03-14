class SubscriptionsUsers < ActiveRecord::Migration
  def self.up
    create_table :subscriptions_users, :id => false do |t|
      t.integer :user_id
      t.integer :subscription_id
    end

  end

  def self.down
    drop_table :subscriptions_users
  end
end
