require 'rubygems'
require 'stemmer'

class NaiveBayes

  # provide a list of categories for this classifier
  def initialize(categories)
    # keeps a hash of word count for each category
    @words = Hash.new		
    @total_words = 0		
    # keeps a hash of number of documents trained for each category
    @categories_documents = Hash.new		
    @total_documents = 0
    @threshold = 1.3
    
    # keeps a hash of number of number of words in each category
    @categories_words = Hash.new
    
    categories.each { |category|         
      @words[category] = Hash.new         
      @categories_documents[category] = 0
      @categories_words[category] = 0
    }
  end

  # train the document
  def train(category, document)
    word_count(document).each do |word, count|
      @words[category][word] ||= 0
      @words[category][word] += count
      @total_words += count
      @categories_words[category] += count
    end
    @categories_documents[category] += 1
    @total_documents += 1
  end

  # find the probabilities for each category and return a hash
  def probabilities(document)
    probabilities = Hash.new
    @words.each_key {|category| 
      probabilities[category] = probability(category, document)
    }
    return probabilities
  end

  # classfiy the document into one of the categories
  def classify(document, default='unknown')
    sorted = probabilities(document).sort {|a,b| a[1]<=>b[1]}
    best,second_best = sorted.pop, sorted.pop
    return best[0] if best[1]/second_best[1] > @threshold
    return default
  end

  def prettify_probabilities(document)
    probs = probabilities(document).sort {|a,b| a[1]<=>b[1]}
    totals = 0
    pretty = Hash.new
    probs.each { |prob| totals += prob[1]}
    probs.each { |prob| pretty[prob[0]] = "#{prob[1]/totals * 100}%"}
    return pretty
  end

  def print_features 
    @words.keys.each { |k|
      arr = @words[k].sort {|a,b| a[1]<=>b[1]} 
      puts "#{k}\n----------------"
      arr[(arr.size - 50)..-1].each do |pair|
        puts "#{pair[0]} - #{pair[1]} #{pair[0][0].to_i}" unless pair[1] == 1
      end
    }
  end


  private

  # the probability of a word in this category
  # uses a weighted probability in order not to have zero probabilities
  def word_probability(category, word)
    #(@words[category][word.stem].to_f + 1)/@categories_words[category].to_f
    (@words[category][word].to_f + 1)/@categories_words[category].to_f
  end

  # the probability of a document in this category
  # this is just the cumulative multiplication of all the word probabilities for this category
  def doc_probability(category, document)
    doc_prob = 1
    word_probs = []
    word_count(document).each { |word| 
      #doc_prob *= word_probability(category, word[0]) 
      word_probs << word_probability(category, word[0])
    }

    # paul graham's suggestion: fifteen most significant
    word_probs.sort.reverse[0..15].each do |p|
      doc_prob *= p
    end
    return doc_prob
  end

=begin UNCOMMENTED OUT ORIGINAL CODE
  def doc_probability(category, document)
    doc_prob = 1
    word_count(document).each { |word| doc_prob *= word_probability(category, word[0]) }
    return doc_prob
  end
=end

  # the probability of a category
  # this is the probability that any random document being in this category
  def category_probability(category)
    @categories_documents[category].to_f/@total_documents.to_f
  end

  # the un-normalized probability of that this document belongs to this category
  def probability(category, document)
    doc_probability(category, document) * category_probability(category)
  end

  # get a hash of the number of times a word appears in any document
  def word_count(document)
    words = document.gsub(/[^\w\s]/,"").split
    d = Hash.new
    words.each do |word|
      #word.downcase! 
      #key = word.stem
      key = word

      # common words are already removed in Entry
     # unless COMMON_WORDS.include?(word.downcase) # remove common words
      d[key] ||= 0
      d[key] += 1
      #end
    end
    return d
  end

end
