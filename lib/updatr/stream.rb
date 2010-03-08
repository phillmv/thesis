# TODO: These two lines are necessary. If these methods are not called
# before loading the classifier, they will fail when called later on.
# I really wish I knew why. Total mindfuck, aggravating bug.
# I FIGURE some class name is clobbering something else but it's not obvious
# what the hell is going on.

Entry.last.classifier_text
Stream.last.category

require 'classifier'
class StreamUpdater
  def initialize(sleep_period)
    @sleep_for = sleep_period
    @last_update = (Time.now - sleep_period) # guarantee update on 1st run

    @classifier = Classifier::Bayes.new "liked", "disliked"

    Classification.liked.each { |e| 
      @classifier.train_liked e.classifier_text 
    }

    Classification.disliked.each { |e| 
      @classifier.train_disliked e.classifier_text 
    }

    self.update!
  end

  # TODO: Should re-rank entries when the number of classifications changes.
  def update!
    if (@last_update + @sleep_for) <= Time.now then
      puts "StreamUpdater updating. It's currently: #{Time.now}" if DEBUG
      
      @last_update = Time.now
      
      Stream.refresh!
      load_class_predictions()
      log "Stream has been refreshed."
      return true
    else
      puts "StreamUpdater: no. It's currently: #{Time.now}" if DEBUG
      return false
    end
  end

  private
  def load_class_predictions
    entries = Stream.unclassified

    entries.each { |e|
      Stream.classify_entry(e, @classifier.classify(e.classifier_text))
  
    }

  end

end
