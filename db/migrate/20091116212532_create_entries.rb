class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries do |t|
      t.string :title
      t.string :url
      t.string :feed_url
      t.date :last_modified
      t.string :author
      t.text :summary
      t.text :content
      t.date :published
      t.date :read
   
      t.integer :feed_id

      t.timestamps
    end
  end

  def self.down
    drop_table :entries
  end
end
