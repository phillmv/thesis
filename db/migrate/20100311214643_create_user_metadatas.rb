class CreateUserMetadatas < ActiveRecord::Migration
  def self.up
    create_table :user_metadatas do |t|
      t.integer :user_id
      t.integer :entry_id
      t.boolean :read

      t.timestamps
    end
  end

  def self.down
    drop_table :user_metadatas
  end
end
