#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)
require 'feedzirra'

#cmdline option, 'debug' will log more & will not sleep.
DEBUG = (ARGV[0] == "debug") ? true : false
SLEEPTIME = DEBUG ? 3 : 1800 # 30mins

# You know, I have a feeling I didn't have to write this.
def log(msg, feeds = nil)
  open("#{RAILS_ROOT}/log/updatr.log", "a") { |io|
    io.puts "#{Time.now.strftime("%d-%m-%y %H:%M")} — #{msg}"
  }

end

# initialize feeds.
@feeds = {}
def init
  @subscriptions = Subscription.all
  @sub_count = Subscription.size  
  @last_sub = @subscriptions.last
  log("Sub count: #{@sub_count}")

  @subscriptions.each do |sub|
    log sub.url if DEBUG

    begin  
      if @feeds[sub.url] != nil then
        if @feeds[sub.url].updated? then
          update(sub.url, @feeds[sub.ur].new_entries)

        end

      else
        @feeds[sub.url] = Feedzirra::Feed.fetch_and_parse(sub.feed_url)
        update(sub.url, @feeds[sub.url].entries)

      end

    rescue Exception => e
      log e.inspect
      log e.backtrace

    end

  end

end

def update(url, entries)
  Subscription.find_by_url(url).add_entries(entries)

end


log("### Starting up... ###\n\n")

init()
# When we initialized our variables, we processed all the new entries.
# Let's wait a standard period before pinging all of feeds again.
sleep SLEEPTIME

loop do
  
  log("Awake. Checking for updates.")

  # TODO Does not account for cases where a subscription has been removed
  if @sub_count != Subscription.size || @last_sub != Subscription.last then
    log("Subs have been added. Fetching new subs.")
    init() #reinitalizes the instance variables, fetches new updates.

  else
    count = 0
    @subscriptions.each { |sub|
      feed = @feeds[sub.url]

      if feed.updated? then
        update(sub.url, feed.entries) if feed.updated?
        count = count + 1
      end
    }

    log "Feeds with updates: #{count}" unless count == 0

  end

  sleep SLEEPTIME 

end




