class ChangeStreams < ActiveRecord::Migration
  def self.up
    drop_table :streams

    create_table :stream do |t|
      t.integer :entry_id
      t.string :rating
      t.integer :size
      t.string :category

    end
  end

  def self.down
    drop_table :stream
  end
end
