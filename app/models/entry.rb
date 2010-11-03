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
    #puts "OMG CLASSIFY"
    
    str = ""

    # author names are far less unique than what is ideal
    str << self.prefix("author", "#{self.author} #{prefix("", self.subscription.title)}") + " "
    
    str << self.prefix("subscription", self.subscription.title)

    concat_bigram_prefix(str, self.title, "title")
    
    [['a', 'href'], ['img', 'src']].each do |pair|
      tag, _attr = pair[0], pair[1]
   
      # LOL AWESOME METHOD CALL LOL
      concat_html_attr(str,
                       Nokogiri::HTML(self.essence),
                       tag,
                       _attr,
                       tag == 'a' ? {:bigram => "link"} : {})
    end
    
    raw_body_text = Nokogiri::HTML("#{self.essence}").text.gsub(/\s/, " ")

    bigram(raw_body_text.split(" ")).each do |word|
      str << " #{word} "
    end
=begin
    without_punctuation(raw_body_text).split(" ").each do |word|
      str << " #{word} " if include_word?(word)
    end
=end

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
    return " " if text.nil? or field.nil? or text.empty?
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
    return if str.nil?
    str.gsub!(/\W\W+/, " ")
    str = str.tr(',?.!;:"@#$%^&*()_=+[]{}\|<>/`~—\-\'' + 194.chr, "" )
    str.strip
  end

  def bigram(word_array)
    words = []
    word_array.each_with_index { |w, i|
      if word = include_word?(w)
        words << "#{word}"

        if !word_array[i+1].nil? && second_word = include_word?(word_array[i+1])
          words << "#{word}_AND_#{second_word}" 
        end
      end
    }
    return words
  end

  def concat_html_attr(str, html, tag, _attr, opt = {})
    html.search(tag).each do |elem|
      if opt[:bigram]
        concat_bigram_prefix(str, elem.content, opt[:bigram])
      end
      begin
        url = URI.split(elem.attributes[_attr])
        str << " #{without_punctuation(url[2])} "
      rescue Exception => e
      end    
    end
  end

  def concat_bigram_prefix(str, text, _prefix = nil)
    bigram(text.split(" ")).each do |word|
      str << " #{prefix(_prefix, word)} #{word} "
    end
    return str
  end


  def include_word?(word)
    w = without_punctuation(word)
    if !(CORPUS_SKIP_WORDS.include?(w.downcase) || w.length <= 2) then
      return w
    else
      return false
    end
  end

CORPUS_SKIP_WORDS = ['a',
'able',
'about',
'above',
'abroad',
'according',
'accordingly',
'across',
'actually',
'adj',
'after',
'afterwards',
'again',
'against',
'ago',
'ahead',
'aint',
'all',
'allow',
'allows',
'almost',
'alone',
'along',
'alongside',
'already',
'also',
'although',
'always',
'am',
'amid',
'amidst',
'among',
'amongst',
'an',
'and',
'another',
'any',
'anybody',
'anyhow',
'anyone',
'anything',
'anyway',
'anyways',
'anywhere',
'apart',
'appear',
'appreciate',
'appropriate',
'are',
'arent',
'around',
'as',
'as',
'aside',
'ask',
'asking',
'associated',
'at',
'available',
'away',
'awfully',
'b',
'back',
'backward',
'backwards',
'be',
'became',
'because',
'become',
'becomes',
'becoming',
'been',
'before',
'beforehand',
'begin',
'behind',
'being',
'believe',
'below',
'beside',
'besides',
'best',
'better',
'between',
'beyond',
'both',
'brief',
'but',
'by',
'c',
'came',
'can',
'cannot',
'cant',
'cant',
'caption',
'cause',
'causes',
'certain',
'certainly',
'changes',
'clearly',
'cmon',
'co',
'co',
'com',
'come',
'comes',
'comments',
'concerning',
'consequently',
'consider',
'considering',
'contain',
'containing',
'contains',
'corresponding',
'could',
'couldnt',
'course',
'cs',
'currently',
'd',
'dare',
'darent',
'definitely',
'described',
'despite',
'did',
'didnt',
'different',
'directly',
'do',
'does',
'doesnt',
'doing',
'done',
'dont',
'down',
'downwards',
'during',
'e',
'each',
'edu',
'eg',
'eight',
'eighty',
'either',
'else',
'elsewhere',
'end',
'ending',
'enough',
'entirely',
'especially',
'et',
'etc',
'even',
'ever',
'evermore',
'every',
'everybody',
'everyone',
'everything',
'everywhere',
'ex',
'exactly',
'example',
'except',
'f',
'fairly',
'far',
'farther',
'few',
'fewer',
'fifth',
'first',
'five',
'followed',
'following',
'follows',
'for',
'forever',
'former',
'formerly',
'forth',
'forward',
'found',
'four',
'from',
'further',
'furthermore',
'g',
'get',
'gets',
'getting',
'given',
'gives',
'go',
'goes',
'going',
'gone',
'got',
'gotten',
'greetings',
'h',
'had',
'hadnt',
'half',
'happens',
'hardly',
'has',
'hasnt',
'have',
'havent',
'having',
'he',
'hed',
'hell',
'hello',
'help',
'hence',
'her',
'here',
'hereafter',
'hereby',
'herein',
'heres',
'hereupon',
'hers',
'herself',
'hes',
'hi',
'him',
'himself',
'his',
'hither',
'hopefully',
'how',
'howbeit',
'however',
'hundred',
'i',
'id',
'ie',
'if',
'ignored',
'ill',
'im',
'immediate',
'in',
'inasmuch',
'inc',
'inc',
'indeed',
'indicate',
'indicated',
'indicates',
'inner',
'inside',
'insofar',
'instead',
'into',
'inward',
'is',
'isnt',
'it',
'itd',
'itll',
'its',
'its',
'itself',
'ive',
'j',
'just',
'k',
'keep',
'keeps',
'kept',
'know',
'known',
'knows',
'l',
'last',
'lately',
'later',
'latter',
'latterly',
'least',
'less',
'lest',
'let',
'lets',
'like',
'liked',
'likely',
'likewise',
'little',
'look',
'looking',
'looks',
'low',
'lower',
'ltd',
'm',
'made',
'mainly',
'make',
'makes',
'many',
'may',
'maybe',
'maynt',
'me',
'mean',
'meantime',
'meanwhile',
'merely',
'might',
'mightnt',
'mine',
'minus',
'miss',
'more',
'moreover',
'most',
'mostly',
'mr',
'mrs',
'much',
'must',
'mustnt',
'my',
'myself',
'n',
'name',
'namely',
'nd',
'near',
'nearly',
'necessary',
'need',
'neednt',
'needs',
'neither',
'never',
'neverf',
'neverless',
'nevertheless',
'new',
'next',
'nine',
'ninety',
'no',
'nobody',
'non',
'none',
'nonetheless',
'noone',
'noone',
'nor',
'normally',
'not',
'nothing',
'notwithstanding',
'novel',
'now',
'nowhere',
'o',
'obviously',
'of',
'off',
'often',
'oh',
'ok',
'okay',
'old',
'on',
'once',
'one',
'ones',
'ones',
'only',
'onto',
'opposite',
'or',
'other',
'others',
'otherwise',
'ought',
'oughtnt',
'our',
'ours',
'ourselves',
'out',
'outside',
'over',
'overall',
'own',
'p',
'particular',
'particularly',
'past',
'per',
'perhaps',
'people',
'placed',
'please',
'plus',
'possible',
'post',
'presumably',
'probably',
'provided',
'provides',
'q',
'que',
'quite',
'qv',
'r',
'rather',
'rd',
're',
'really',
'reasonably',
'recent',
'recently',
'regarding',
'regardless',
'regards',
'relatively',
'respectively',
'right',
'round',
's',
'said',
'same',
'saw',
'say',
'saying',
'says',
'second',
'secondly',
'see',
'seeing',
'seem',
'seemed',
'seeming',
'seems',
'seen',
'self',
'selves',
'sensible',
'sent',
'serious',
'seriously',
'seven',
'several',
'shall',
'shant',
'she',
'shed',
'shell',
'shes',
'should',
'shouldnt',
'since',
'six',
'so',
'some',
'somebody',
'someday',
'somehow',
'someone',
'something',
'sometime',
'sometimes',
'somewhat',
'somewhere',
'soon',
'sorry',
'specified',
'specify',
'specifying',
'still',
'sub',
'such',
'sup',
'sure',
't',
'tags',
'take',
'taken',
'taking',
'tell',
'tends',
'th',
'than',
'thank',
'thanks',
'thanx',
'that',
'thatll',
'thats',
'thats',
'thatve',
'the',
'their',
'theirs',
'them',
'themselves',
'then',
'thence',
'there',
'thereafter',
'thereby',
'thered',
'therefore',
'therein',
'therell',
'therere',
'theres',
'theres',
'thereupon',
'thereve',
'these',
'they',
'theyd',
'theyll',
'theyre',
'theyve',
'thing',
'things',
'think',
'third',
'thirty',
'this',
'thorough',
'thoroughly',
'those',
'though',
'three',
'through',
'throughout',
'thru',
'thus',
'till',
'to',
'together',
'too',
'took',
'toward',
'towards',
'tried',
'tries',
'truly',
'try',
'trying',
'ts',
'twice',
'two',
'u',
'un',
'under',
'underneath',
'undoing',
'unfortunately',
'unless',
'unlike',
'unlikely',
'until',
'unto',
'up',
'upon',
'upwards',
'us',
'use',
'used',
'useful',
'uses',
'using',
'usually',
'v',
'value',
'various',
'versus',
'very',
'via',
'viz',
'vs',
'w',
'want',
'wants',
'was',
'wasnt',
'way',
'we',
'wed',
'welcome',
'well',
'well',
'went',
'were',
'were',
'werent',
'weve',
'what',
'whatever',
'whatll',
'whats',
'whatve',
'when',
'whence',
'whenever',
'where',
'whereafter',
'whereas',
'whereby',
'wherein',
'wheres',
'whereupon',
'wherever',
'whether',
'which',
'whichever',
'while',
'whilst',
'whither',
'who',
'whod',
'whoever',
'whole',
'wholl',
'whom',
'whomever',
'whos',
'whose',
'why',
'will',
'willing',
'wish',
'with',
'within',
'without',
'wonder',
'wont',
'would',
'wouldnt',
'x',
'y',
'yes',
'yet',
'you',
'youd',
'youll',
'your',
'youre',
'yours',
'yourself',
'yourselves',
'youve',
'z',
'zero']

end
