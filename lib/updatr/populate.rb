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

  count = 0

  @subscriptions.each do |sub|
    log sub.url if DEBUG

    begin  
      if @feeds[sub.url] != nil then
        if update!(sub.url) then
          count = count + 1
        
        end

      else
        feed = Feedzirra::Feed.fetch_and_parse(sub.feed_url)
        if feed == 0 then
          # change sub count to force reinit on next cycle.
          @sub_count = @sub_count - 1
          raise "Feed init for #{sub.url} failed. How's your internet connection?"
        else
          @feeds[sub.url] = feed
        end
        Subscription.find_by_url(sub.url).
          add_entries(@feeds[sub.url].entries)     
        count = count + 1

      end

    rescue Exception => e
      log e.inspect
      log e.backtrace

    end

  end

  log "Feeds with updates: #{count}"
end

def update!(url)
  begin
    feed = Feedzirra::Feed.update(@feeds[url])
    if feed == 0 then
      raise "Feed update failed for #{url}. How's your internet connection?"
    else
      @feeds[url] = feed
    end

    if feed.updated? then
      log "#{url} has updates." if DEBUG
      Subscription.find_by_url(url).add_entries(feed.new_entries)
      return true

    end

  rescue Exception => e
    log e.inspect
    log e.backtrace
  end

  return false
end


log("### Starting up... ###\n\n")

init()
# When we initialized our variables, we processed all the new entries.
# Let's wait a standard period before pinging all of feeds again.
sleep SLEEPTIME

loop do
  
  log("Awake.")

  # TODO: does not remove deleted items off update list until daemon restart
  if @sub_count != Subscription.size || @last_sub != Subscription.last then
    log("Feed list has changed. Refetching feeds.")
    init() #reinitalizes the instance variables, fetches new updates.

  else
    count = 0
    @subscriptions.each do |sub|
        if update!(sub.url) then
          count = count + 1
        
        end

    end

    log "Feeds with updates: #{count}"

  end

  sleep SLEEPTIME 
end
