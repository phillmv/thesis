class Entry < ActiveRecord::Base
  belongs_to :subscription
  has_one :classification

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

  def read!
    if self.read.nil?
      self.read = Time.now
    else
      self.read = nil
    end
    self.save!
  end

  def liked!
    classify("liked", true)
  end

  def liked?
    return false if self.classification.nil?

    return self.classification["liked"]
  end

  def disliked?
    return false if self.classification.nil?

    return !self.classification["liked"]
  end


  def disliked!
    classify("liked", false)
  end

  private
  def self.shuffle!(arr) 
    arr.each_index do |i| 
      j = rand(arr.length-i) + i
      arr[j], arr[i] = arr[i], arr[j]  
    end
  end

  def classify(attribute, val)
    if self.classification.nil? then
      self.classification = Classification.new
      self.classification.entry_id = self.id
    end
    self.classification[attribute] = val
    self.classification.save!
  end

end
