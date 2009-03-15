#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require File.join(File.dirname(__FILE__), "jitter")

Daemons.run_proc('jitter.rb') do
  Jitter.start
end