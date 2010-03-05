class Classification < ActiveRecord::Base
  belongs_to :entry

  def self.liked
    Entry.find_by_sql("select * from entries where (select entry_id from classifications where entry_id = entries.id and classifications.liked is true);")
  end

  def self.disliked
    Entry.find_by_sql("select * from entries where (select entry_id from classifications where entry_id = entries.id and classifications.liked is false);")
  end
end
