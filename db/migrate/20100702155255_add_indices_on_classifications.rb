class AddIndicesOnClassifications < ActiveRecord::Migration
  def self.up
    add_index :classifications, :user_id
    add_index :classifications, :entry_id
  end

  def self.down
    remove_index :classifications, :user_id
    remove_index :classifications, :entry_id
  end
end
