class Classification < ActiveRecord::Base
  belongs_to :entry
  belongs_to :user

  def self.liked(user)
    Entry.find_by_sql(["select * from entries where (select entry_id from classifications where entry_id = entries.id and classifications.liked is true and classifications.user_id = ?);", user.id])
  end

  def self.disliked(user)
    Entry.find_by_sql(["select * from entries where (select entry_id from classifications where entry_id = entries.id and classifications.liked is false and classifications.user_id = ?);", user.id])
  end
end
