class SubscriptionsUsers < ActiveRecord::Base; end

class AddDefaultCreatedAtToPreviousSubscriptionsUsers < ActiveRecord::Migration
  def self.up
    SubscriptionsUsers.connection.execute("update subscriptions_users set created_at = '2010-05-01 00:00:00' where created_at is null")
  end

  def self.down
    no_going_back!
  end
end
