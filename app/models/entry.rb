class Entry < ActiveRecord::Base
  # taken from: 
  # http://www.igvita.com/2006/09/07/validating-url-in-ruby-on-rails/
  VALID_URL = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix

  # Internal field separator
  # If this ever changes the classifier must be retrained
  # classifier strips out all common punctuation, so uncommon char = win
  IFS = '§'
    
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
      
      e.content = massage_html(e, entry.content) unless entry.content == nil
      e.summary = massage_html(e, entry.summary) unless entry.summary == nil

      e.published = entry.published
      e.author = entry.author

      e.save!
    }
  end

  def classifier_text
    # let's start simple. Ideally should be adding qualifiers like
    # weighing link text more heavily.

    prefix("author", self.author) << 
      prefix("subscription", self.subscription.title) <<
        prefix("title", self.title) <<
          Hpricot(self.essence).to_plain_text.strip
  end
  
  def essence
    if content.nil?
      return summary
    else
      return content
    end
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

  # appends prefixes to fields
  # assumes field is a single word, removes spaces from text and appends a 
  # space at the end for serial concatenation.
  def prefix(field = nil, text = nil)
    return " " if text.nil?
    "#{field}#{IFS}#{text.gsub(/ /,'')} "
  end

  def self.massage_html(entry, text)
    h = Hpricot(text)

    # Can you believe some people use script js includes instead of
    # object tags for videos? This broke the app 'cos a faulty script 
    # replaced the whole DOM with the object tag instead of just magically 
    # figuring out where it was supposed to go
    # What a braindead pattern; pretty sure Google Reader does this too.

    h.search("script").remove # <3 Hpricot

    # fuck you, foreign policy blog
    # (in their cms they never add the domain for their blog pics)
    # I am positive google reader does this exact same thing

    # TODO: Validate subscription URLs such that they always have a 
    # leading forward slash (/)
    h.search("img").each do |elem| 
      if !(VALID_URL === elem.attributes['src']) then
        new_src = (entry.subscription.url + elem.attributes['src'])

        # Let's be sure I don't fuck this up.
        if VALID_URL === new_src then
          elem.attributes['src'] = new_src
        end
      end
    end
    
    h.inner_html

  end

end
