require File.join(File.dirname(__FILE__), *%w[jitter])

class Jitter
  class Configuration
    def setup
      if File.exist?(Jitter.config_path)
        puts "Your configuration file exists at #{Jitter.config_path}"
      else
        config_dir = File.join(ENV['HOME'], '.jitter')
        FileUtils.mkdir(config_dir) unless File.exist?(config_dir)
        File.open(Jitter.config_path, 'w') do |f|
          f.write({
            :accept_from => 'YOUR_JABBER_ACCOUNT',
            :jabber => {:username => 'JABBER_TWITTER_GATEWAY_ACCOUNT', :password => 'PASSWORD'},
            :twitter => {:username => 'YOUR_USERNAME', :password => 'YOUR_PASSWORD'},
            :searches => []
          }.to_yaml)
        end
        puts "Config created in #{Jitter.config_path}"
      end
    end
  
    def console
      setup
      require 'irb'
      IRB.setup(nil)
      IRB.conf[:PROMPT][:APP] = IRB.conf[:PROMPT][:SIMPLE]
      IRB.conf[:PROMPT][:APP][:PROMPT_I] = 'jitter> '
      IRB.conf[:PROMPT_MODE] = :APP
      irb = IRB::Irb.new(IRB::WorkSpace.new(self))
      IRB.conf[:MAIN_CONTEXT] = irb.context

      trap('SIGINT') { puts "Config not saved" && exit(0) }

      catch(:IRB_EXIT) do
        puts "Type 'config' to see your configuration"
        irb.eval_input
        puts
        save
      end
    end

    attr_reader :config
    
    def initialize
      @config = YAML.load_file(Jitter.config_path)
    end

    def save
      return unless @config
      puts "Saving config to #{Jitter.config_path}"
      File.open(Jitter.config_path, 'w') { |f| f.write @config.to_yaml }
    end
  end
end