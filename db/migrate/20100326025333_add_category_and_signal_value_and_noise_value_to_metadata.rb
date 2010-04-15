class AddCategoryAndSignalValueAndNoiseValueToMetadata < ActiveRecord::Migration
  def self.up
    add_column :metadata, :category, :string
    add_column :metadata, :signal_value, :string
    add_column :metadata, :noise_value, :string
  end

  def self.down
    remove_column :metadata, :noise_value
    remove_column :metadata, :signal_value
    remove_column :metadata, :category
  end
end
