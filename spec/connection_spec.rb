
require 'spec_helper'


describe RabbitMQ::Connection do
  let(:subject_class) { RabbitMQ::Connection }
  
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
      expect { subject.start }.to raise_error RabbitMQ::Connection::DestroyedError
      expect { subject.close }.to raise_error RabbitMQ::Connection::DestroyedError
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
    
    it "can be called before connecting to no effect" do
      subject.close
    end
  end
  
  describe "when given no URL" do
    subject { subject_class.new }
    
    its(:user)     { should eq "guest" }
    its(:password) { should eq "guest" }
    its(:host)     { should eq "localhost" }
    its(:vhost)    { should eq "/" }
    its(:port)     { should eq  5672 }
    it             { should_not be_ssl }
  end
  
  describe "when given a URL" do
    subject { subject_class.new(url) }
    let(:url) { "amqp://user:password@host:1234/vhost" }
    
    its(:user)     { should eq "user" }
    its(:password) { should eq "password" }
    its(:host)     { should eq "host" }
    its(:vhost)    { should eq "vhost" }
    its(:port)     { should eq  1234 }
    it             { should_not be_ssl }
  end
  
  describe "when given an SSL URL" do
    subject { subject_class.new(url) }
    let(:url) { "amqps://user:password@host:1234/vhost" }
    
    its(:user)     { should eq "user" }
    its(:password) { should eq "password" }
    its(:host)     { should eq "host" }
    its(:vhost)    { should eq "vhost" }
    its(:port)     { should eq  1234 }
    it             { should be_ssl }
  end
end
