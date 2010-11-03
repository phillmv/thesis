#!/usr/bin/env ruby

require 'naive_bayes'
require File.expand_path('../../../config/environment',  __FILE__)


CAT = ["liked", "disliked"]
@data = {CAT[0] => [], CAT[1] => []}
@liked = Classification.liked(User.first)
@disliked = Classification.disliked(User.first)

@data["liked"] = @liked
@data["disliked"] = @disliked

@n = NaiveBayes.new(CAT)

CAT.each do |c|
  @data[c].each do |i|
  @n.train(c, i.classifier_text)
  end
end

puts @n.classify(Entry.last.classifier_text)
puts "lol eof"



