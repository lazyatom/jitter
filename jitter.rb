#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'
require 'cgi'

config = YAML.load_file(File.expand_path("~/.jitter.yaml"))

im = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])

def post_update_to_twitter(im, twitter, config)
  im.received_messages do |message|
    if config[:accept_from].include?(message.from.strip.to_s)
      twitter.post(message.body, :source => "Jabber")
    end
  end
end

def new_messages(twitter)
  last_seen_path = File.expand_path("~/.jitter.last_seen") 
  last_seen = Time.parse(File.read(last_seen_path)) rescue Time.new - (60*60*24) # yesterday
  messages = twitter.timeline.select { |status| Time.parse(status.created_at) > last_seen }.reverse
  if messages.any?
    File.open(last_seen_path, 'w') do |f| 
      f.write messages.last.created_at
    end
  end
  messages
end

def post_tweets_to_im(im, twitter, config)
  messages = new_messages(twitter)
  if config[:show_messages_from] && config[:restrict_shown_messages]
    messages.delete_if { |s| !config[:show_messages_from].include?(s.user.screen_name) }
  end
  messages.each do |status|
    config[:accept_from].each do |user|
      message = CGI.unescapeHTML(status.text)
      tweeter = status.user.name
      im.deliver(user, "[#{tweeter}] #{message}") rescue nil
    end
  end
end

updates = Thread.new do
  loop do
    post_update_to_twitter(im, twitter, config)
    sleep(1)
  end
end

timeline = Thread.new do
  loop do
    post_tweets_to_im(im, twitter, config)
    sleep(30)
  end
end

[updates, timeline].map { |t| t.join }
