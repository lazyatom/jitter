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
    @log = Logger.new($stdout)
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
    twitter.post(status, :source => "JitterBot")
  end
  
  def say(tweet)
    message = CGI.unescapeHTML(tweet.text)
    config[:accept_from].each do |jabber_account|
      jabber.deliver(jabber_account, "[#{tweet.user.name}] #{message}")
    end
  end

  private
  
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
  
end

if __FILE__ == $0

  def every(seconds)
    Thread.new do
      loop do
        yield
        sleep(seconds)
      end
    end
  end
  
  jitter = Jitter.new
  [
    every(1) { jitter.post_update_to_twitter }, 
    every(30) { jitter.post_tweets_to_im }
  ].map { |t| t.join }
end