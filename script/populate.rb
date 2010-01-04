#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'feedzirra'

feed_urls = [ 'http://waxy.org/links/index.xml', 'http://www.themorningnews.org/rss.xml', 'http://feeds.kottke.org/main', 'http://www.foreignpolicy.com/issue/foreignpolicy.php' ]

feeds = Feedzirra::Feed.fetch_and_parse(feed_urls)

feeds.keys.each { |u|
  Feed.parse(feeds[u])
}




