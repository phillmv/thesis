class Entry < ActiveRecord::Base
  # must reference class name before being able to use it (wtf?!)
  Hpricot
  require 'digest/md5'
  require 'nokogiri'

  # taken from: 
  # http://www.igvita.com/2006/09/07/validating-url-in-ruby-on-rails/
  VALID_URL = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix

  # Internal field separator
  # If this ever changes the classifier must be retrained
  # classifier strips out all common punctuation, so uncommon char = win
  IFS = '§'
    
  belongs_to :subscription
  has_many :classification
  has_many :metadata, :class_name => "Metadata"

  
  # can't use false or null values, but that is OK.
  # maybe I'm being presumptuous but I feel like I'm always running into
  # AR edge cases.
  def title
    read_attribute(:title) or "(title unknown)"
  end

  def self.shuffled
    shuffle!(self.all)
  end

  def self.generate_unique_id(sub_url, entry_url)
    @@digest ||= Digest::MD5
    @@digest.hexdigest(sub_url + entry_url)
  end

  def self.parse(entries, subscription)
    entries.each { |entry|

      entry_url = entry.url
      # obviously a copy from below, that should be refactored.
      if !(VALID_URL === entry_url) then
        entry_url = URI::join(subscription.url, entry_url).to_s
      end

      unique_hash = Entry.generate_unique_id(subscription.url, entry_url)

      e = Entry.find_or_create_by_unique_id(unique_hash)
      e.title = entry.title
      e.subscription = subscription
      e.url = entry_url
      
      e.content = massage_html(e, entry.content) unless entry.content == nil
      e.summary = massage_html(e, entry.summary) unless entry.summary == nil

      # haaaaaaack
      if entry.published.nil?
        e.published = Time.now
      else
        e.published = entry.published
      end
      e.author = entry.author

      e.save!
    }
  end

  def classifier_text
    # let's start simple. Ideally should be adding qualifiers like
    # weighing link text more heavily.
    
    str = ""

    # author names are far less unique than what is ideal
    str << self.prefix("author", "#{self.author} #{prefix("", self.subscription.title)}") + " "
    
    #str <<  self.prefix("author", self.author)
    str << self.prefix("subscription", self.subscription.title)
   
    title_array = self.title.split(" ")

    str << bigram(title_array).collect { |w|
      word = without_punctuation(w)
      " #{prefix("title", word) } " if include_word?(word)
    }.join(" ")

    without_punctuation(Nokogiri::HTML("#{self.title} #{self.essence}").text.gsub(/\s/, " ")).split(" ").each { |word|
        if include_word?(word)
          str << " #{word} "
        end
      }

      return str
  end
  
  def essence
    if content.nil?
      return summary
    else
      return content
    end
  end

  def self.shuffle!(arr) 
    arr.each_index do |i| 
      j = rand(arr.length-i) + i
      arr[j], arr[i] = arr[i], arr[j]  
    end
  end

  # appends prefixes to fields
  # assumes field is a single word, removes spaces from text and appends a 
  # space at the end for serial concatenation.
  def prefix(field = nil, text = nil)
    return " " if text.nil?
    "#{field}#{IFS}#{text.gsub(/ /,'')}"
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
        new_src = URI::join(entry.subscription.url, elem.attributes['src']).to_s

        elem.attributes['src'] = new_src
      end
    end
    
    h.inner_html

  end

  def without_punctuation(str)
    str.gsub!(/\W\W+/, " ")
    str.tr(',?.!;:"@#$%^&*()_=+[]{}\|<>/`~—\-\'', "" )
  end

  def bigram(word_array)
    words = []
    word_array.each_with_index { |w, i|
      words << "#{w}"
      words << "#{w}_AND_#{word_array[i+1]}" unless word_array[i+1].nil?
    }
    return words
  end

  def include_word?(word)
    if !(CORPUS_SKIP_WORDS.include?(word.downcase) || word.length <= 2) then
      return word
    else
      return false
    end
  end


  CORPUS_SKIP_WORDS = [
    "a",
    "again",
    "all",
    "along",
    "are",
    "also",
    "an",
    "and",
    "as",
    "at",
    "but",
    "by",
    "came",
    "can",
    "cant",
    "couldnt",
    "comments",
    "did",
    "didn",
    "didnt",
    "do",
    "doesnt",
    "dont",
    "ever",
    "first",
    "from",
    "have",
    "her",
    "here",
    "him",
    "how",
    "i",
    "if",
    "in",
    "into",
    "is",
    "isnt",
    "it",
    "itll",
    "just",
    "last",
    "least",
    "like",
    "most",
    "my",
    "new",
    "no",
    "not",
    "now",
    "of",
    "on",
    "or",
    "posts",
    "should",
    "sinc",
    "so",
    "some",
    "tags",
    "th",
    "than",
    "this",
    "that",
    "the",
    "their",
    "then",
    "those",
    "to",
    "told",
    "too",
    "true",
    "try",
    "until",
    "url",
    "us",
    "were",
    "when",
    "whether",
    "while",
    "with",
    "within",
    "yes",
    "you",
    "youll",
  ]


end
