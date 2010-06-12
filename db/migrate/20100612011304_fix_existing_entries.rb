class FixExistingEntries < ActiveRecord::Migration
  def self.up
    # We have to fix the stuff already in the database to keep up
    # with the stuff we've already parsed innit
    #
    # Slower this way but this is a one time operation that we might as well
    # keep within the same timezone (not that this matters really)
    entries = Entry.find_by_sql("select * from entries where published is null")
    entries.each do |e|
      e.published = Time.now
      e.save!
    end
  end

  def self.down
    oh_noes_fuck!
  end
end
