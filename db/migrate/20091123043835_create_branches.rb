class CreateBranches < ActiveRecord::Migration
  def self.up
    create_table :branches do |t|
      t.entry_id :integer
      t.stream_id :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :branches
  end
end
