class Subscription < ActiveRecord::Base
  has_many :entries
=begin
  # TODO: need to add new subscriptions
  def self.parse(feed)
    f = Subscription.find_or_create_by_url(feed.url)
    f.url = feed.url
    f.feed_url = feed.feed_url
    f.last_modified = feed.last_modified
    f.etag = feed.etag
    f.title = feed.title
    f.save!

    feed.entries.each { |e|
      Entry.parse(e, f)
    }
  end
=end

  def self.size
    self.count_by_sql("select count(id) from subscriptions")
  end

  def add_entries(entries)
    Entry.parse(entries, self)
  end
end
