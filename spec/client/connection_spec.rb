
require 'spec_helper'


describe RabbitMQ::Client::Connection do
  let(:subject_class) { RabbitMQ::Client::Connection }
  
  describe "destroy" do
    it "is not necessary to call" do
      subject
    end
    
    it "can be called several times to no additional effect" do
      subject.destroy
      subject.destroy
      subject.destroy
    end
    
    it "prevents any other network operations on the object" do
      subject.destroy
      expect { subject.start }.to raise_error RabbitMQ::Client::DestroyedError
      expect { subject.close }.to raise_error RabbitMQ::Client::DestroyedError
    end
  end
  
  describe "start" do
    it "initiates the connection to the server" do
      subject.start
    end
    
    it "can be called several times to reconnect" do
      subject.start
      subject.start
      subject.start
    end
  end
  
  describe "close" do
    it "closes the initiated connection" do
      subject.start
      subject.close
    end
    
    it "can be called several times to no additional effect" do
      subject.start
      subject.close
      subject.close
      subject.close
    end
    
    it "can be called before destroy" do
      subject.start
      subject.close
      subject.destroy
    end
    
    it "can be called before connecting to no effect" do
      subject.close
    end
  end
  
  it "uses Util.connection_info to parse info from its creation arguments" do
    args = ["parsable url", { foo: "bar" }]
    RabbitMQ::Util.should_receive(:connection_info).with(*args) {{
      user:     "user",
      password: "password",
      host:     "host",
      vhost:    "vhost",
      port:     1234,
      ssl:      false
    }}
    subject = subject_class.new(*args)
    
    subject.options[:user]    .should eq "user"
    subject.options[:password].should eq "password"
    subject.options[:host]    .should eq "host"
    subject.options[:vhost]   .should eq "vhost"
    subject.options[:port]    .should eq 1234
    subject.options[:ssl]     .should eq false
  end
  
  describe "remaining_timeout" do
    it "returns nil when given a timeout of nil" do
      subject.remaining_timeout(nil).should eq nil
    end
    
    it "returns 0 when time has already run out" do
      time_now = Time.now
      subject.remaining_timeout(0,   time_now)      .should eq 0
      subject.remaining_timeout(5.0, time_now - 5)  .should eq 0
      subject.remaining_timeout(5.0, time_now - 10) .should eq 0
      subject.remaining_timeout(5.0, time_now - 100).should eq 0
    end
    
    it "returns the remaining time when there is time remaining" do
      subject.remaining_timeout(10.0, Time.now-5).should be_within(1.0).of(5.0)
    end
  end
  
end
