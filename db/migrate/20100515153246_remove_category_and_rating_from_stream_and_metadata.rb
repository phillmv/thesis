class RemoveCategoryAndRatingFromStreamAndMetadata < ActiveRecord::Migration
  def self.up
    remove_column :stream, :category
    remove_column :stream, :rating
    remove_column :metadata, :category 
  end

  def self.down
    nothing_we_can_do_really
  end
end
