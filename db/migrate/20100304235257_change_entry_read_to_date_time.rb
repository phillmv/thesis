class ChangeEntryReadToDateTime < ActiveRecord::Migration
  def self.up
    change_column :entries, :read, :datetime
  end

  def self.down
    change_column :entries, :read, :date
  end
end
