#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)
require File.dirname(__FILE__) + '/feeds'

# cmdline option, 'debug' will log more & will not sleep.
# This needs to be pushed out to configuration.
DEBUG = (ARGV[0] == "debug") ? true : false
SLEEPTIME = DEBUG ? 30.seconds.to_i : 3.minutes.to_i

FEED_SLEEP = 30.minutes

# You know, I have a feeling I didn't have to write this.
def log(msg, feeds = nil)
  open("#{RAILS_ROOT}/log/updatr.log", "a") { |io|
    io.puts "#{Time.now.strftime("%d-%m-%y %H:%M")} — #{msg}"
  }

end

log("### Starting up... ###\n\n")
@services = []
@services << FeedUpdater.new(FEED_SLEEP)
# When we initialized our variables, we processed all the new entries.
# Let's wait a standard period before pinging all of feeds again.

sleep SLEEPTIME

loop do
  
  # This feels unsatisfactory. The idea behind this is that I now have a
  # need for multiple background processing. I kind of want this to be
  # asynchronous - what if a service hangs? Right now processing takes 
  # about ten seconds, so it's not a big deal.
  
  @services.each do |serv|
    serv.update!
  
  end
  
  sleep SLEEPTIME 
end
