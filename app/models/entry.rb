class Entry < ActiveRecord::Base
  belongs_to :subscription

  named_scope :unread, :order => "published ASC", :conditions => { :read => nil }

  def self.shuffled
    shuffle!(self.all)
  end

  def self.parse(entries, subscription)
    entries.each { |entry|
      e = Entry.find_or_create_by_url(entry.url)
      e.title = entry.title
      e.subscription = subscription
      e.summary = entry.summary
      e.content = entry.content
      e.published = entry.published
      e.author = entry.author

      e.save!
    }
  end

  private
  def self.shuffle!(arr) 
    arr.each_index do |i| 
      j = rand(arr.length-i) + i
      arr[j], arr[i] = arr[i], arr[j]  
    end
  end


end
