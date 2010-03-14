class RemoveReadFromEntries < ActiveRecord::Migration
  def self.up
    remove_column :entries, :read
  end

  def self.down
    add_column :entries, :read, :datetime
  end
end
