class RenameUserMetatadasMetadata < ActiveRecord::Migration
  def self.up
    rename_table :user_metadatas, :metadata
  end

  def self.down
    rename_table :metadata, :user_metadatas
  end
end
