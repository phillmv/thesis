class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title
      t.string :url
      t.string :feed_url
      t.date :last_modified
      t.string :etag

      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
