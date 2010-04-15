#!/usr/bin/env ruby
require File.expand_path('../../../config/environment',  __FILE__)
require File.dirname(__FILE__) + '/feeds'
require File.dirname(__FILE__) + '/stream'

# cmdline option, 'debug' will log more & will not sleep.
# This needs to be pushed out to configuration.
DEBUG = (ARGV[0] == "debug") ? true : false
SLEEPTIME = DEBUG ? 30.seconds.to_i : 3.minutes.to_i

FEED_SLEEP = 30.minutes
STREAM_SLEEP = 3.minutes

# You know, I have a feeling I didn't have to write this.
def log(msg, feeds = nil)
  open("#{RAILS_ROOT}/log/updatr.log", "a") { |io|
    io.puts "#{Time.now.strftime("%d-%m-%y %H:%M")} — #{msg}"
  }

end

log("### Starting up... ###\n\n")
@services = []

# Services should be able to recover from 'lack of internet'. If
# the initialization propagates an exception then Something Is Wrong,
# Quit Really Loudly
begin
  @services << FeedUpdater.new(FEED_SLEEP)
  @services << StreamUpdater.new(STREAM_SLEEP)
rescue Exception => e
  log e.inspect
  log e.backtrace
  log("Ugh. Exception at init. Quitting.")
  exit 1
end
# When we initialized our variables, we processed all the new entries.
# Let's wait a standard period before pinging all of feeds again.

sleep SLEEPTIME

loop do
  
  # This feels unsatisfactory. The idea behind this is that I now have a
  # need for multiple background processing. I kind of want this to be
  # asynchronous - what if a service hangs? Right now processing takes 
  # about ten seconds, so it's not a big deal.
  begin
    @services.each do |serv|
      serv.update!

    end
  rescue Exception => e
    log e.inspect
    log e.backtrace
  end
  
  sleep SLEEPTIME 
end
