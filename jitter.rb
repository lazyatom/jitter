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
    @current_status = nil
  end

  def post_update_to_twitter
    jabber.presence_updates do |update|
      account, presence, message = update
      if config[:accept_from].include?(account) && message && message != current_status
        twitter.post(message, :source => "Jitter")
        @current_status = message
      end
    end
  end

  def post_tweets_to_im(im, twitter, config)
    new_messages(twitter).each do |status|
      config[:accept_from].each do |user|
      end
    end
  end

  private
  
  def send_tweet_to_jabber(tweet, jabber_account)
    begin
      message = CGI.unescapeHTML(tweet.text)
      jabber.deliver(jabber_account, "[#{tweet.user.name}] #{message}")
    rescue
    end    
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
    @last_seen_path ||= File.expand_path("~/.jitter.last_seen")
  end
  
end

if __FILE__ == $0
  jitter = Jitter.new
  [
    Thread.new do
      loop do
        jitter.post_update_to_twitter
        sleep(1)
      end
    end# , 
    #   Thread.new do
    #     loop do
    #       jitter.post_tweets_to_im
    #       sleep(30)
    #     end
    #   end
  ].map { |t| t.join }
end