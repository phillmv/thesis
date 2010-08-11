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

    str << bigram(self.title.split(" ")).collect { |w|
      if include_word?(w) then
        word = without_punctuation(w)
        " #{prefix("title", word) } #{word} "
      end
    }.join(" ")

    Nokogiri::HTML(self.essence).search('a').each do |link|
      bigram(link.content.split(" ")).collect do |w|
        if include_word?(w) then 
          word = without_punctuation(w)
        str << " #{prefix("link", word)} #{word} "
        end
      end

      # URI parser is way more strict than desirable
      begin
        url = URI.split(link.attributes["href"])
        str << without_punctuation(url[2])
      rescue Exception => e
        #puts "Exception on: #{self.id} — #{link.attributes["href"]}"
      end

    end


    raw_body_text = Nokogiri::HTML("#{self.essence}").text.gsub(/\s/, " ")
    without_punctuation(raw_body_text).split(" ").each do |word|
      str << " #{word} " if include_word?(word)
    end

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
    return if str.nil?
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
'ain\'t',
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
'aren\'t',
'around',
'as',
'a\'s',
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
'can\'t',
'caption',
'cause',
'causes',
'certain',
'certainly',
'changes',
'clearly',
'c\'mon',
'co',
'co.',
'com',
'come',
'comes',
'concerning',
'consequently',
'consider',
'considering',
'contain',
'containing',
'contains',
'corresponding',
'could',
'couldn\'t',
'course',
'c\'s',
'currently',
'd',
'dare',
'daren\'t',
'definitely',
'described',
'despite',
'did',
'didn\'t',
'different',
'directly',
'do',
'does',
'doesn\'t',
'doing',
'done',
'don\'t',
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
'hadn\'t',
'half',
'happens',
'hardly',
'has',
'hasn\'t',
'have',
'haven\'t',
'having',
'he',
'he\'d',
'he\'ll',
'hello',
'help',
'hence',
'her',
'here',
'hereafter',
'hereby',
'herein',
'here\'s',
'hereupon',
'hers',
'herself',
'he\'s',
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
'i\'d',
'ie',
'if',
'ignored',
'i\'ll',
'i\'m',
'immediate',
'in',
'inasmuch',
'inc',
'inc.',
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
'isn\'t',
'it',
'it\'d',
'it\'ll',
'its',
'it\'s',
'itself',
'i\'ve',
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
'let\'s',
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
'mayn\'t',
'me',
'mean',
'meantime',
'meanwhile',
'merely',
'might',
'mightn\'t',
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
'mustn\'t',
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
'needn\'t',
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
'no-one',
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
'one\'s',
'only',
'onto',
'opposite',
'or',
'other',
'others',
'otherwise',
'ought',
'oughtn\'t',
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
'placed',
'please',
'plus',
'possible',
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
'shan\'t',
'she',
'she\'d',
'she\'ll',
'she\'s',
'should',
'shouldn\'t',
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
'that\'ll',
'thats',
'that\'s',
'that\'ve',
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
'there\'d',
'therefore',
'therein',
'there\'ll',
'there\'re',
'theres',
'there\'s',
'thereupon',
'there\'ve',
'these',
'they',
'they\'d',
'they\'ll',
'they\'re',
'they\'ve',
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
't\'s',
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
'wasn\'t',
'way',
'we',
'we\'d',
'welcome',
'well',
'we\'ll',
'went',
'were',
'we\'re',
'weren\'t',
'we\'ve',
'what',
'whatever',
'what\'ll',
'what\'s',
'what\'ve',
'when',
'whence',
'whenever',
'where',
'whereafter',
'whereas',
'whereby',
'wherein',
'where\'s',
'whereupon',
'wherever',
'whether',
'which',
'whichever',
'while',
'whilst',
'whither',
'who',
'who\'d',
'whoever',
'whole',
'who\'ll',
'whom',
'whomever',
'who\'s',
'whose',
'why',
'will',
'willing',
'wish',
'with',
'within',
'without',
'wonder',
'won\'t',
'would',
'wouldn\'t',
'x',
'y',
'yes',
'yet',
'you',
'you\'d',
'you\'ll',
'your',
'you\'re',
'yours',
'yourself',
'yourselves',
'you\'ve',
'z',
'zero']  


end
