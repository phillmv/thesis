require 'digest/md5'
class AddUniqueIdToEntries < ActiveRecord::Migration
  def self.up
    m = Digest::MD5.new
    add_column :entries, :unique_id, :string
    Entry.all.each do |e|
      e.unique_id = m.hexdigest(e.subscription.url + e.url)
      e.save!
    end
    add_index :entries, :unique_id
  end


  def self.down
    remove_column :entries, :unique_id
  end
end
