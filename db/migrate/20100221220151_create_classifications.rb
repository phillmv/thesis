class CreateClassifications < ActiveRecord::Migration
  def self.up
    create_table :classifications do |t|
      t.integer :entry_id
      t.boolean :clicked
      t.boolean :clicked_title
      t.boolean :liked

      t.timestamps
    end
  end

  def self.down
    drop_table :classifications
  end
end
