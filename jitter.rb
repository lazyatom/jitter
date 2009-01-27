#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'
require 'tempfile'
require 'cgi'

config = YAML.load_file(File.expand_path("~/.jitter.yaml"))

im = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])

tmp = Tempfile.new('most_recent_status_timestamp')
last_seen_path = tmp.path
tmp.close!

updates = Thread.new do
  loop do
    im.received_messages do |message|
      if config[:accept_from].include?(message.from.strip.to_s)
        puts "Posting '#{message.body}' to twitter."
        twitter.post(message.body, :source => "Jabber")
      else
        puts "Rejecting message from #{message.from} (#{message.body})"
      end
    end
    sleep(1)
  end
end

timeline = Thread.new do
  loop do
    last_seen = Time.parse(File.read(last_seen_path)) rescue Time.new - (60*60*24) # yesterday
    messages = twitter.timeline.select do |status| 
      config[:show_messages_from].include?(status.user.screen_name) && 
        Time.parse(status.created_at) > last_seen
    end
    puts "Found #{messages.length} new messages"
    File.open(last_seen_path, 'w') { |f| f.puts messages.first.created_at.to_yaml } if messages.any?
    messages.each do |status|
      config[:accept_from].each do |user|
        puts "sending to #{user}"
        im.deliver(user, "[#{status.user.name}] #{CGI.unscapeHTML(status.text)}") rescue nil
      end
    end
    sleep(30)
  end
end

updates.join
timeline.join