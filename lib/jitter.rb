#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r-simple'
require 'twitter'
require 'yaml'
require 'cgi'
require 'logger'

class Jitter
  def self.config_path
    File.expand_path("~/.jitter/config.yaml")
  end
  
  attr_reader :current_status, :jabber, :twitter, :config, :log
  
  def initialize(config=YAML.load_file(Jitter.config_path))
    @config = config
    @jabber = Jabber::Simple.new(config[:jabber][:account], config[:jabber][:password])
    @twitter = Twitter::Base.new(config[:twitter][:account], config[:twitter][:password])
    setup_logging
  end

  def post_update_to_twitter
    log.debug "checking updates."
    jabber.reconnect unless jabber.connected?
    jabber.received_messages do |message|
      log.info "Received from #{message.from.strip}: #{message}"
      if sender_is_authorized?(message)
        tweet(message.body)
      else
        log.warn "Message from an unknown source (#{message.from.strip}); only accepting from #{config[:accept_from].join(", ")}"
      end
    end
  rescue StandardError => e
    log.error e
  end

  def post_tweets_to_im
    messages_to_send = new_messages
    log.debug "sending #{messages_to_send.length} updates."
    messages_to_send.each do |tweet|
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
      message_text = formatted_for_jabber(tweet)
      log.debug "Sending: #{message_text}"
      jabber.deliver(jabber_account, message_text)
    end
  end

  private
  
  def sender_is_authorized?(message)
    config[:accept_from].include?(message.from.strip.to_s)
  end
  
  def formatted_for_jabber(tweet)
    case tweet
    when Twitter::Status
      "_#{tweet.user.screen_name} (#{tweet.user.name})_\n#{message}"
    when Twitter::DirectMessage
      "*DM* _#{tweet.sender_screen_name}_\n#{message}"
    when Twitter::SearchResult
      "_#{tweet.from_user}_\n#{tweet.text}"
    end
  end
  
  def new_messages
    last_seen = File.read(last_seen_path).to_i rescue 0
    messages = all_twitter_messages.select { |status| status.id.to_i > last_seen }
    File.open(last_seen_path, 'w') { |f| f.write messages.last.id } if messages.any?
    messages
  end
  
  def all_twitter_messages
    (twitter.timeline + twitter.direct_messages + search_messages).sort_by { |tweet| Time.parse(tweet.created_at) }
  end
  
  def search_messages
    (@config[:searches] || []).map { |s| Twitter::Search.new(s).fetch["results"] }.flatten
  end
  
  def last_seen_path
    File.expand_path("~/.jitter/last_seen_id")
  end
  
  def setup_logging
    logfile = case config[:logfile]
    when :stdout
      $stdout
    when nil
      "/dev/null"
    else
      config[:logfile]
    end
    @log = Logger.new(logfile)
    log.level = config[:log_level] || Logger::INFO
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