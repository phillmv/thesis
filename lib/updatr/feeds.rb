require 'feedzirra'

# basically a singleton or a namespace; wrapping these methods as class
# methods feels 'wrong', but I haven't the time to lookup a better pattern
# expects ActiveRecord to be loaded; I wonder again

#TODO:  Some kind of refactoring? I like the idea of there being an abstract
# class that all services can inherit from. I also have the sneaking
# suspicion that there is almost certainly a worker framework I could've
# used instead.

class FeedUpdater

  def initialize(sleep_period)
    @feeds = {}
    @sleep_for = sleep_period
    @last_update = Time.now
    init()
  end

  def update!
    if (@last_update + @sleep_for) <= Time.now then
      puts "Updating. It's currently: #{Time.now}" if DEBUG

      @last_update = Time.now
      # TODO: does not remove deleted items off update list until daemon 
      # restart
      if @sub_count != Subscription.size || @last_sub != Subscription.last then
        log("Feed list has changed. Refetching feeds.")
        init() #reinitalizes the instance variables, fetches new updates.

      else
        count = 0
        @subscriptions.each do |sub|
          if load_feeds!(sub.url) then
            count = count + 1

          end

        end

        log "FeedUpdater: updated #{count} feeds."

      end
      return true

    else
      puts "Not time yet. It's currently: #{Time.now}" if DEBUG
      return false

    end
  end

  private
  def load_feeds!(url)
    begin
      feed = Feedzirra::Feed.update(@feeds[url])
      log "Feed class: #{@feeds[url].class}, url: #{url}" #debug
      if feed.class == Fixnum then
        raise "Feed update failed for #{url} with value #{feed}. How's your internet connection?"
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
          if load_feeds!(sub.url) then
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

end
