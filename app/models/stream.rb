class Stream < ActiveRecord::Base
  set_table_name "stream"

  belongs_to :entry

  def self.entries
    Entry.find_by_sql("select * from entries where (select entry_id from stream where entries.id = stream.entry_id)")
  end

  def self.refresh!
    Stream.transaction do
      Stream.connection.execute("insert into stream (entry_id) select id from entries where entries.read is null and not exists (select entry_id from stream where entries.id != stream.entry_id);")
      Stream.connection.execute("delete from stream where (select id from entries where entries.id = stream.entry_id and entries.read is not null);")
    end
  end

  def self.unclassified
    Entry.find_by_sql("select * from entries where (select entry_id from stream where stream.entry_id = entries.id and stream.category is null);")
  end

  def self.classify_entry(entry, classification)
    stream = Stream.find_by_entry_id(entry.id)
    stream.category = classification
    stream.save!
  end

end
