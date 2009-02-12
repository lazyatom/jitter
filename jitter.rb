#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'
require 'cgi'

class Jitter
  attr_reader :current_status, :jabber, :twitter, :config
  def initialize(config=YAML.load_file(File.expand_path("~/.jitter.yaml")))
    @config = config
    @jabber = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
    @twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])
  end

  def post_update_to_twitter
    jabber.presence_updates do |update|
      account, presence, message = update
      if config[:accept_from].include?(account) && message && message != current_status
        self.current_status = message
      end
    end
  end

  def post_tweets_to_im
    new_messages(twitter).each do |tweet|
      config[:accept_from].each do |user|
        send_tweet_to_jabber(tweet, user)
      end
    end
  end
  
  def current_status=(status)
    twitter.post(status, :source => "JitterBot")
    File.open(current_status_path, 'w') { |f| f.write status }
  end
  
  def current_status
    File.read(current_status_path) rescue nil
  end
  
  private
  
  def send_tweet_to_jabber(tweet, jabber_account)
    message = CGI.unescapeHTML(tweet.text)
    jabber.deliver(jabber_account, "[#{tweet.user.name}] #{message}")   
  end

  def new_messages(twitter)
    last_seen = Time.parse(File.read(last_seen_path)) rescue Time.new - (60*60*24) # yesterday
    messages = twitter.timeline.select { |status| Time.parse(status.created_at) > last_seen }.reverse
    if messages.any?
      File.open(last_seen_path, 'w') do |f| 
        f.write messages.last.created_at
      end
    end
    messages
  end
  
  def last_seen_path
    File.expand_path("~/.jitter.last_seen")
  end
  
  def current_status_path
    File.expand_path("~/.jitter.status")
  end
  
end

if __FILE__ == $0
  jitter = Jitter.new
  [
    Thread.new do
      loop do
        begin
          jitter.post_update_to_twitter
        rescue Error => e
          puts "error: #{e}"
        end
        sleep(1)
      end
    end, 
    Thread.new do
      loop do
        begin
          jitter.post_tweets_to_im
        rescue Error => e
          puts "error: #{e}"
        end
        sleep(30)
      end
    end
  ].map { |t| t.join }
end