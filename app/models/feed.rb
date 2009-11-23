class Feed < ActiveRecord::Base
  def self.parse(feed)
    f = Feed.find_or_create_by_url(feed.url)
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
end
