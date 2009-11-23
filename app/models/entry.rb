class Entry < ActiveRecord::Base
  belongs_to :feed

  def self.shuffled
    shuffle!(self.all)
  end

  def self.parse(entry, feed)
    e = Entry.find_or_create_by_url(entry.url)
    e.title = entry.title
    e.feed = feed
    e.summary = entry.summary
    e.content = entry.content
    e.published = entry.published
    e.author = entry.author

    e.save!
  end

  private
  def self.shuffle!(arr) 
    arr.each_index do |i| 
      j = rand(arr.length-i) + i
      arr[j], arr[i] = arr[i], arr[j]  
    end
  end


end
