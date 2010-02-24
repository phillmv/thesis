#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

Daemons.run(File.dirname(File.expand_path(__FILE__)) + "/populate.rb", { :app_name => "updatr.rb", :dir_mode => :normal, :dir => File.expand_path('../../../tmp/pids',  __FILE__)})
