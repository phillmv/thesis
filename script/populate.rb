#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'feedzirra'

feed_urls = [ 'http://waxy.org/links/index.xml', 'http://feeds.feedburner.com/ffffound/everyone' ]

feeds = Feedzirra::Feed.fetch_and_parse(feed_urls)

feeds.keys.each { |u|
  Feed.parse(feeds[u])
}




