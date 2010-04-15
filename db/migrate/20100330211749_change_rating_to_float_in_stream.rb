class ChangeRatingToFloatInStream < ActiveRecord::Migration
  def self.up
    change_column :stream, :rating, :float
  end

  def self.down
    change_column :stream, :rating, :string
  end
end
