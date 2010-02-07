#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)
require 'feedzirra'

def log(msg, feeds = nil)
  open("#{RAILS_ROOT}/log/updatr.log", "a") { |io|
    io.puts "#{Time.now}\n#{msg}"
    io.puts "Applying #{feeds.size} feeds." unless feeds == nil
    io.puts "###\n\n"
  }
end

wd = File.expand_path('../', __FILE__)
log("STARTING UP")

loop do
  feed_urls = Feed.all.collect { |f| f.feed_url }

  log("UPDATING FEEDS", feed_urls)

  feeds = Feedzirra::Feed.fetch_and_parse(feed_urls)
  feeds.keys.each { |u|
    Feed.parse(feeds[u])
  }
  sleep 60 * 60 #1 hr
end




