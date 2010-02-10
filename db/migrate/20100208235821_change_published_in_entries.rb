class ChangePublishedInEntries < ActiveRecord::Migration
  def self.up
    change_column :entries, :published, :datetime
  end

  def self.down
    oh_noes
  end
end
