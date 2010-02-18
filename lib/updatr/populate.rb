#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)
require 'feedzirra'

SLEEPTIME = 3600 # 1hr

DEBUG = false
#cmdline option, 'debug' will log more & will not sleep.
DEBUG = true if ARGV[0] == "debug"

# You know, I have a feeling I didn't have to write this.
def log(msg, feeds = nil)
  open("#{RAILS_ROOT}/log/updatr.log", "a") { |io|
    io.puts "#{Time.now.strftime("%d-%m-%y %H:%M")} — #{msg}"
  }

end

def update(url, entries)
  log("looking at #{url}")
  Subscription.find_by_url(url).add_entries(entries)

end

log("### Starting up... ###\n\n")

subscriptions, sub_count, last_sub, feeds = nil, nil, nil, {}

loop do

  # initialize or check to see if list has changed.
  if sub_count != Subscription.size || last_sub != Subscription.last then

    subscriptions = Subscription.all
    sub_count = Subscription.size  
    last_sub = subscriptions.last

    log("Sub count: #{sub_count}")

    subscriptions.each { |sub|
      log sub.url if DEBUG

      begin  
        entries = nil
        
        if feeds[sub.url] != nil
          entries = feeds[sub.ur].new_entries if feeds[sub.url].updated?
        
        else
          feeds[sub.url] = Feedzirra::Feed.fetch_and_parse(sub.feed_url)
          entries = feeds[sub.url].entries
        
        end
        
        update(sub.url, entries) unless entries == nil

      rescue Exception => e
        log e.inspect
        log e.backtrace

      end
    }

  else
    subscriptions.each { |sub|
      feed = feeds[sub.url]
      update(sub.url, feed.entries) if feed.updated?
    }

  end

  sleep SLEEPTIME unless DEBUG
end




