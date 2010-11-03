#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)

# fuck my life. I need to find out why this happens...
Entry.last.classifier_text
require 'classifimicator'
require 'ruby-debug'

class Validation

  attr_reader :proc_entries, :classifiers
  CATEGORIES = [:signal, :noise]

  def initialize(classifiers, signal_set, noise_set)
    load_classifiers(classifiers)
    @training_data = { :signal => signal_set, :noise => noise_set } 
  end

  def cross_validate
    puts "\n\n"

    @cross_validation = {}
    cross_results = {}
    precision = {}

    
    CATEGORIES.each do |cat|
      puts "Partinioning #{cat}."
      @cross_validation[cat] = partition(@training_data[cat].clone)

      @classifiers.each do |c|
        cross_results[c.library] ||= {}
        cross_results[c.library][cat] = { :size => 0, :correct => 0 }
      end
    end

    @held_data = {}
    @classifiers.each do |c|
      precision[c.library] = {}
    end
    
    10.times do |i|

      puts "\nRound #{i}"
      
      CATEGORIES.each do |cat|
        @held_data[cat] = @cross_validation[cat][i]

        puts "Training #{cat}." 
        @cross_validation[cat].each_with_index do |array, j|
          if j != i then
            train(@cross_validation[cat][j], cat)
          end
        end 
      end



      # wait until both categories are trained.
      @classifiers.each do |c|
        precision[c.library][i] = {}
        
        puts "Validating with #{c.library}:"

        CATEGORIES.each do |cat|
          
          res = validate(c, @held_data[cat], cat)
          precision[c.library][i][cat] = { :tp => res[0], :fn => res[2] }
          
          prev_size = cross_results[c.library][cat][:size]
          prev_correct = cross_results[c.library][cat][:correct]

          cross_results[c.library][cat][:size] = res[1] + prev_size 
          cross_results[c.library][cat][:correct] = res[0] + prev_correct
          
        end

        precision_recall(precision[c.library][i], :signal)
      end

      puts "\nResetting classifiers...\n\n"
      load_classifiers
    end

    puts "----------"
    cross_results.each_pair do |lib, v|
      puts "Average results for #{lib}:"
      v.each_pair do |cat, res|
        puts "#{cat}: #{ppc(res[:size], res[:correct])}"
      end
      puts "\n"
    end

    total_precision = {}
    @classifiers.each do |c|
      total_precision[c.library] = {}
      CATEGORIES.each do |cat|
        total_precision[c.library][cat] = { :tp => 0, :fn => 0 }
        cat_hash = total_precision[c.library][cat]
        10.times do |i|
          cat_hash[:tp] = precision[c.library][i][cat][:tp] + cat_hash[:tp]

          cat_hash[:fn] = precision[c.library][i][cat][:fn] + cat_hash[:fn]
        end
      end

      puts "\n\nTotal classification stats for #{c.library}:"
      precision_recall(total_precision[c.library], :signal)
    end
    debugger 
    puts "\n"
  end

  def validate(classifier, set, value)
    true_p = 0
    false_n = 0
    set.each do |i|
      if classifier.predict(i.classifier_text) == value then
        true_p = true_p + 1
      else
        false_n = false_n + 1
      end
    end
    puts "#{value}: #{true_p} / #{set.size}\t\t\t #{ppc(set.size, true_p)}"
    
    return [ true_p, set.size, false_n ]
  end

  def partition(dataset)
    size = (dataset.size.to_f / 10.0).floor
    collection = Array.new(10)
    pos = 0

    10.times do |i|
      size.times do |j|
        collection[i] ||= []
        collection[i] << dataset.delete_at(rand(dataset.size))
        #puts dataset.size
      end
    end

    dataset.each do |i|
      collection[9] << i
    end

=begin
    10.times do |i|
      #puts "from #{pos} to #{pos+size}"
      if i == 9
        collection[i] = dataset[pos..-1]
      else
        collection[i] = dataset[pos..pos+size]
      end

      pos = pos+size + 1
    end
=end

    return collection

  end

  def decimate(dataset, storageset)
    dataset.reject { |i| 
      if rand(10) >= 9 then 
        storageset << i; 
        i 
      end 
    }
  end

  def train(set, cat)
    @classifiers.each do |c|
      #puts "Training #{c.library} on #{cat} entries."      
      set.each { |i| c.train cat, i.classifier_text }
    end
  end

  def process(set)
    @proc_entries = { }

    [:signal, :noise].each do |cat|
      train(@training_data[cat], cat)
    end

    
    @classifiers.each do |c|
      @proc_entries[c.library] = { :signal => [], :noise => [] }
      @proc_entries[c.library].default = []

      set.each do |i|
        prediction = c.predict(i.classifier_text) 
        @proc_entries[c.library][prediction] << i.id
      end
    end

    puts "Processing complete. Total entries: #{set.size}."
    puts "\n\n"

    @classifiers.each do |c|
      ssize = @proc_entries[c.library][:signal].size
      nsize = @proc_entries[c.library][:noise].size
      puts "#{c.library} results:"
      puts "Signal: #{ssize} (#{ppc(set.size, ssize)})"
      puts "Noise: #{nsize} (#{ppc(set.size, nsize)})"
      puts c.print_features
      puts "\n\n"
    end
  end

  private
  def load_classifiers(classifiers = nil)
    @loaded_classifiers ||= classifiers
    @classifiers = []
    @loaded_classifiers.each do |c| 
      @classifiers << Classifimicator.new(c)
    end

  end

  def ppc(total, sub)
    "%0.2f\%" % ((sub.to_f / total.to_f) * 100)
  end

  def precision_recall(results, perspective)
    true_p = 0
    false_n = 0
    
    true_n = 0
    false_p = 0

    results.each_pair do |k, v|
      if k == perspective
        true_p = v[:tp]
        false_n = v[:fn]
      else
        true_n = v[:tp]
        false_p = v[:fn]
      end
    end
    puts "Precision is: #{true_p} / #{true_p} + #{false_p} =\t\t #{ppc(true_p + false_p, true_p)}"
    puts "Recall is: #{true_p} / #{true_p} + #{false_n} =\t\t #{ppc(true_p + false_n, true_p)}"
    puts "True Neg is #{true_n} / #{true_n} + #{false_p} =\t\t #{ppc(true_n + false_p, true_n)}"
    puts "Accuracy is #{true_p} + #{true_n} / #{true_p} + #{true_n} + #{false_p} + #{false_n} =\t #{ppc(true_p + true_n + false_p + false_n, true_p + true_n)}"
    puts "\n\n"
    
  end

end

classifiers = %w(classifier naive_bayes crm114)

@liked = Classification.liked(User.first)
@disliked = Classification.disliked(User.first)

v = Validation.new(classifiers, @liked, @disliked)

v.cross_validate

#=begin
@e = Entry.find_by_sql('select * from entries e where e.id in (select m.entry_id from metadata m where m.user_id = 1) order by e.published DESC limit 1000')

puts "Testing overall entry population:"

v = Validation.new(classifiers, @liked, @disliked)
v.process(@e)
#=end
=begin
#@e = Entry.find_by_sql('select * from entries e where e.id in (select m.entry_id from metadata m where m.user_id = 1) order by e.published DESC limit 1000')

debugger
#train(@classifier, @liked, :liked)
#train(@classifier, @disliked, :disliked)

predictions = { :liked => [], :disliked => [] }
@e.each do |i|
  puts "Processing: #{i.attributes["id"]}"
  predictions[@classifier.predict(i.classifier_text)] << i
end

debugger



=begin
@classifiers = [ 
  Classifimicator.new("bishop"),
  Classifimicator.new("crm114"),
  Classifimicator.new("naive_bayes"),
  Classifimicator.new("classifier")
]
@liked = Classification.liked(User.first)
@disliked = Classification.disliked(User.first)

puts "\n\n"
puts "Total signal size: #{@liked.size}"
puts "Total noise size: #{@disliked.size}"

@test_l = []
@liked = decimate(@liked, @test_l)

@test_d = []
@disliked = decimate(@disliked, @test_d)

puts "\n\n"
puts "Size of signal-test: #{@test_l.size}"
puts "Size of noise-test: #{@test_d.size}"
puts "\n\n"
puts "Remaining signal: #{@liked.size}\n"
puts "Remaining noise: #{@disliked.size}\n"

@classifiers.each do |classifier|
  puts "Training #{classifier.library}"
  train(classifier, @liked, :liked)
  train(classifier, @disliked, :disliked)
end

puts "\nTesting instances:"

@classifiers.each do |classifier|
  validate(classifier, @test_l, :liked)
  validate(classifier, @test_d, :disliked)
end

=end
