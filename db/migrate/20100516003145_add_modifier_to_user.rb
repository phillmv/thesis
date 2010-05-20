class AddModifierToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :modifier, :integer
  end

  def self.down
    remove_column :users, :modifier
  end
end
