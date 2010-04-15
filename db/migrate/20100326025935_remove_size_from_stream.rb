class RemoveSizeFromStream < ActiveRecord::Migration
  def self.up
    remove_column :stream, :size
  end

  def self.down
    add_column :stream, :size, :integer
  end
end
