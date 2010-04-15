class ChangeReadToDatetimeInMetadata < ActiveRecord::Migration
  def self.up
    change_column :metadata, :read, :datetime
  end

  def self.down
    change_column :metadata, :read, :boolean
  end
end
