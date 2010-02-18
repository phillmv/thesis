#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

Daemons.run("populate.rb", { :app_name => "updatr.rb", :dir_mode => :normal, :dir => File.expand_path('../../../tmp/pids',  __FILE__)})
