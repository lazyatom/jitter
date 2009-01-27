#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'

config = YAML.load_file(File.expand_path("~/.jitter.yaml"))

im = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])
accept_from = config[:accept_from]

loop do
  im.received_messages do |message|
    if accept_from.include?(message.from.strip.to_s)
      puts "Posting '#{message.body}' to twitter."
      twitter.post(message.body, :source => "Jabber")
    else
      puts "Rejecting message from #{message.from} (#{message.body})"
    end
  end
  sleep(1)
end
