class AddIndexOnUserIdAndEntryIdInStream < ActiveRecord::Migration
  def self.up
    add_index :stream, :user_id
    add_index :stream, :entry_id
  end

  def self.down
    remove_index :stream, :user_id
    remove_index :stream, :entry_id
  end
end
