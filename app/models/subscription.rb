require 'feedzirra'
class Subscription < ActiveRecord::Base
  has_and_belongs_to_many :user
  validates_uniqueness_of :url
  validates_uniqueness_of :feed_url
  
  has_many :entries
  after_create :parse

  # TODO really needs to be pushed out into a library/daemon
  def parse
    begin
      feed = Feedzirra::Feed.fetch_and_parse(self.feed_url) 
    rescue Exception => e
      puts e.inspect
      puts e.backtrace
      return nil
    end
    self.url = feed.url
    self.title = feed.title
    self.save!
    self.add_entries(feed.entries)
  end

  def self.size
    self.count_by_sql("select count(id) from subscriptions")
  end

  def add_entries(entries)
    Entry.parse(entries, self)
  end
end
