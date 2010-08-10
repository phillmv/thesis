class Classifimicator
  CRM114 = "crm114"
  BISHOP = "bishop"
  CLASSIFIER = "classifier"
  NAIVE = "naive_bayes"

  @classifier = nil
  attr_reader :library

  def initialize(library = "classifier")
    @library = library
    
    case @library
    when BISHOP
      require 'bishop'
      @classifier = Bishop::Bayes.new { |probs, ignore| Bishop::robinson(probs, ignore) }

    when CRM114
      require 'crm114'
      @classifier = Classifier::CRM114.new([:signal, :noise])

    when NAIVE
      require 'naive_bayes'
      @classifier = NaiveBayes.new(["signal", "noise"])

    when CLASSIFIER
      require 'classifier'
      @classifier = Classifier::Bayes.new "signal", "noise"


    else puts "What the fuck are you doing here?"
    end

  end

  def train(category, text)
    case @library
    when CRM114
      @classifier.train!(category, text) 

    when CLASSIFIER
      @classifier.train(category, text)

    when BISHOP
      @classifier.train(category.to_s, text)

    when NAIVE
      @classifier.train(category.to_s, text)
    end
  end

  def predict(text)
    case @library
    when CRM114
      @classifier.classify(text)[0]

    when CLASSIFIER 
      @classifier.classify(text).downcase.to_sym 

    when BISHOP
       res = @classifier.guess(text)

       results = res.sort_by{ |score| -score.last }
       results.first[0].to_sym
    
    when NAIVE 
      @classifier.classify(text).to_sym 

    end
  end

  def print_features
    @classifier.try(:print_features)
  end
end
