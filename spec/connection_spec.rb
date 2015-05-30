
require 'spec_helper'


describe RabbitMQ::Connection do
  let(:subject_class) { RabbitMQ::Connection }
  
  describe "destroy" do
    it "can be called several times to no additional effect" do
      subject.destroy
      subject.destroy
      subject.destroy
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
