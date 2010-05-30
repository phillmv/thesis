require 'feedzirra'
class Subscription < ActiveRecord::Base
  has_and_belongs_to_many :user
  has_many :entries
 
  validates_uniqueness_of :url
  validates_uniqueness_of :feed_url
  validate :feed_url_integrity
  validate :feed_integrity
  
  after_validation_on_create :parse
  after_create :add_entries
  

  def parse
    return false unless errors.empty?
    self.url = @feed.url
    self.title = @feed.title
  end

  def self.size
    self.count_by_sql("select count(id) from subscriptions")
  end

  def add_entries
    Entry.parse(@feed.entries, self) unless @feed.nil?
  end

  private

  def feed_url_integrity
     if !(Entry::VALID_URL === self.feed_url) then
       errors.add(:feed_url, "is invalid! Please try again.")
       return false
     else
       return true
     end
  end

  def feed_integrity
    if errors[:feed_url] then
      # no point in trying.
      return false
    
    else
      @feed = Feedzirra::Feed.fetch_and_parse(self.feed_url) 

      if @feed.nil? || @feed.class == Fixnum then
        errors.add(:feed, "seems to not be a valid RSS/Atom/Whatever file. Please try again!")
        return false

      else
        return true
      end
    end
  end

end
