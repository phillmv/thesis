class ChangeSignalValueAndNoiseValueInMetadataToFloat < ActiveRecord::Migration
  def self.up
    change_column :metadata, :signal_value, :float
    change_column :metadata, :noise_value, :float
  end

  def self.down
    change_column :metadata, :signal_value, :string
    change_column :metadata, :noise_value, :string
  end
end
