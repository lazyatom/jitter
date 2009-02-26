#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'
require 'cgi'
require 'logger'

class Jitter
  attr_reader :current_status, :jabber, :twitter, :config, :log
  def initialize(config=YAML.load_file(File.expand_path("~/.jitter.yaml")))
    @config = config
    @jabber = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
    @twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])
    @log = Logger.new("/dev/null")
    log.level = Logger::INFO
  end

  def post_update_to_twitter
    log.debug "checking updates."
    jabber.received_messages do |message|
      log.info "Received from #{message.from.strip}: #{message}"
      if config[:accept_from].include?(message.from.strip.to_s)
        tweet(message.body)
      else
        log.warn "Message from an unknown source (#{message.from.strip}); only accepting from #{config[:accept_from].join(", ")}"
      end
    end
  rescue StandardError => e
    log.error e
  end

  def post_tweets_to_im
    log.debug "sending updates."
    new_messages(twitter).each do |tweet|
      say(tweet)
    end
  rescue StandardError => e
    log.error e
  end
  
  def tweet(status)
    log.info "Posting '#{status}'"
    if status =~ /^d\s(\w+)\s(.+)/
      twitter.d($1, $2)
    else
      twitter.post(status, :source => "JitterBot")
    end
  end
  
  def say(tweet)
    message = CGI.unescapeHTML(tweet.text)
    config[:accept_from].each do |jabber_account|
      message_text = case tweet
      when Twitter::Status
        "_#{tweet.user.screen_name}_\n#{message}"
      when Twitter::DirectMessage
        "*DM* _#{tweet.sender_screen_name}_\n#{message}"
      end
      log.debug "Sending: #{message_text}"
      jabber.deliver(jabber_account, message_text)
    end
  end

  private
  
  def new_messages(twitter)
    last_seen = Time.parse(File.read(last_seen_path)) rescue Time.new - (60*60*24) # yesterday
    messages = all_twitter_messages.select { |status| Time.parse(status.created_at) > last_seen }
    if messages.any?
      File.open(last_seen_path, 'w') do |f| 
        f.write messages.last.created_at
      end
    end
    messages
  end
  
  def all_twitter_messages
    (twitter.timeline + twitter.direct_messages).sort_by { |tweet| Time.parse(tweet.created_at) }
  end
  
  def last_seen_path
    File.expand_path("~/.jitter.last_seen")
  end
  
  def self.every(seconds)
    Thread.new do
      loop do
        yield
        sleep(seconds)
      end
    end
  end
  
  def self.start
    jitter = Jitter.new
    [every(1) { jitter.post_update_to_twitter }, 
     every(30) { jitter.post_tweets_to_im }].map { |t| t.join }
  end
end

if __FILE__ == $0
  Jitter.start
end