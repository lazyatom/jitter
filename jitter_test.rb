require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'jitter'

class JitterTest < Test::Unit::TestCase
  
  context "when listening for updates" do
    setup do
      @jabber = stub_jabber
      @twitter = stub_twitter
      @jitter = Jitter.new(config(:accept_from => ["james@lazyatom.com"]))
    end
    
    should "ignore updates from accounts it doesn't know" do
      @jabber.stubs(:presence_updates).yields(["notjames@lazyatom.com", :online, nil])
      @twitter.expects(:post).never
      @jitter.post_update_to_twitter
    end
    
    should "update twitter when status message is changed" do
      @jabber.stubs(:presence_updates).yields(["james@lazyatom.com", :online, "is happy as larry"])
      @twitter.expects(:post).with("is happy as larry", anything)
      @jitter.post_update_to_twitter
    end
    
    should "not update twitter if the message is not present" do
      @jabber.stubs(:presence_updates).yields(["james@lazyatom.com", :online, nil])
      @twitter.expects(:post).never
      @jitter.post_update_to_twitter
    end
    
    should "not update twitter if the message is not changed" do
      @jabber.stubs(:presence_updates).yields(["james@lazyatom.com", :online, "is happy"])
      @jitter.post_update_to_twitter
      
      @jabber.stubs(:presence_updates).yields(["james@lazyatom.com", :away, "is happy"])
      @twitter.expects(:post).never
      @jitter.post_update_to_twitter
    end
    
    should "not update twitter if the message matches the last status" do
      @jitter.stubs(:current_status).returns("is happy")
      @jabber.stubs(:presence_updates).yields(["james@lazyatom.com", :away, "is happy"])
      @twitter.expects(:post).never
      @jitter.post_update_to_twitter
    end
  end
  
  context "when listening to twitter" do
    setup do
      @jabber = stub_jabber
      @jitter = stub_twitter
      @jitter = Jitter.new
    end
    
    should "send updates to jabber" do
      
    end
  end
  
  private
  
  def config(overrides={})
    {
      :accept_from => ["test@example.com"],
      :jabber => {
        :account => "test@example.com",
        :password => "password"
      },
      :twitter => {
        :account => "test@example.com",
        :password => "password"
      }
    }.merge(overrides)
  end
  
  def stub_jabber
    Jabber::Simple.stubs(:new).returns(jabber = stub_everything('jabber stub'))
    return jabber
  end
  
  def stub_twitter
    Twitter::Base.stubs(:new).returns(twitter = stub_everything('twitter stub'))
    return twitter
  end
  
end
