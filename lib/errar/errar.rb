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

    
    CATEGORIES.each do |cat|
      puts "Partinioning #{cat}."
      @cross_validation[cat] = partition(@training_data[cat].clone)

      @classifiers.each do |c|
        cross_results[c.library] ||= {}
        cross_results[c.library][cat] = { :size => 0, :correct => 0 }
      end
    end

    @held_data = {}
    
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

        CATEGORIES.each do |cat|
          res = validate(c, @held_data[cat], cat)
          
          prev_size = cross_results[c.library][cat][:size]
          prev_correct = cross_results[c.library][cat][:correct]

          cross_results[c.library][cat][:size] = res[1] + prev_size 
          cross_results[c.library][cat][:correct] = res[0] + prev_correct
          
        end
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
  end

  def validate(classifier, set, value)
    puts "Validating #{value} class with #{classifier.library}:"
    p_correct = 0
    set.each do |i|
      if classifier.predict(i.classifier_text) == value then
        p_correct = p_correct + 1
      end
    end
    puts "ERRAR RATE: #{p_correct} / #{set.size} (#{ppc(set.size, p_correct)})"

    return [ p_correct, set.size ]
  end

  def partition(dataset)
    size = (dataset.size.to_f / 10.0).floor
    collection = Array.new(10)
    pos = 0

    10.times do |i|
      size.times do |j|
        collection[i] ||= []
        collection[i] << dataset.delete_at(rand(dataset.size))
        puts dataset.size
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
end

classifiers = %w(crm114 naive_bayes)

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
