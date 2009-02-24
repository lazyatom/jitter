#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require File.join(File.dirname(__FILE__), "jitter")

Daemons.daemonize
Jitter.start
