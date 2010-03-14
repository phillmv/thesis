class AddUserIdToClassifications < ActiveRecord::Migration
  def self.up
    add_column :classifications, :user_id, :integer
  end

  def self.down
    remove_column :classifications, :user_id
  end
end
