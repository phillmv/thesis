class AddPublishedToStream < ActiveRecord::Migration
  def self.up
    add_column :stream, :published, :datetime
  end

  def self.down
    remove_column :stream, :published
  end
end
