class AddUserIdToStream < ActiveRecord::Migration
  def self.up
    add_column :stream, :user_id, :integer
  end

  def self.down
    remove_column :stream, :user_id
  end
end
