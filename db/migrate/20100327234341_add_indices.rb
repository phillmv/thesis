class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :entries, :url
    add_index :entries, :id
    add_index :entries, :published
    add_index :entries, :subscription_id
    add_index :metadata, :entry_id
    add_index :metadata, :user_id
  end

  def self.down
    remove_index :entries, :url
    remove_index :entries, :id
    remove_index :entries, :published
    remove_index :entries, :subscription_id
    remove_index :metadata, :entry_id
    remove_index :metadata, :user_id
  end
end
