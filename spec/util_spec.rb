
require 'spec_helper'


describe RabbitMQ::Util do
  it { should be }
  
  describe "error_check" do
    it "returns nil when given an ok result code" do
      subject.error_check(:foo, :ok).should eq nil
    end
    
    it "raises an error when given an error result code" do
      expect { subject.error_check(:foo, :no_memory) }.to \
        raise_error RabbitMQ::FFI::Error::NoMemory, /foo/
    end
  end
  
  describe "null_check" do
    it "returns nil when given a non-nil object" do
      subject.null_check(:foo, Object.new).should eq nil
    end
    
    it "raises an error when given nil" do
      expect { subject.null_check(:foo, nil) }.to \
        raise_error RabbitMQ::FFI::Error, /foo/
    end
  end
  
  describe "connection_info" do
    it "given no arguments returns default values" do
      subject.connection_info.should eq(
        user:     "guest",
        password: "guest",
        host:     "localhost",
        vhost:    "/",
        port:     5672,
        ssl:      false
      )
    end
    
    it "given a URL parses values from the URL" do
      subject.connection_info(
        "amqp://user:password@host:1234/vhost"
      ).should eq(
        user:     "user",
        password: "password",
        host:     "host",
        vhost:    "vhost",
        port:     1234,
        ssl:      false
      )
      
      subject.connection_info(
        "amqp://host"
      ).should eq(
        user:     "guest",
        password: "guest",
        host:     "host",
        vhost:    "/",
        port:     5672,
        ssl:      false
      )
    end
    
    it "given an SSL URL parses values from the URL" do
      subject.connection_info(
        "amqps://user:password@host:1234/vhost"
      ).should eq(
        user:     "user",
        password: "password",
        host:     "host",
        vhost:    "vhost",
        port:     1234,
        ssl:      true
      )
    end
    
    it "given options overrides the default values with the options" do
      subject.connection_info(
        user:     "foo",
        password: "bar",
        port:     5678,
        ssl:      true
      ).should eq(
        user:     "foo",
        password: "bar",
        host:     "localhost",
        vhost:    "/",
        port:     5678,
        ssl:      true
      )
    end
    
    it "given a URL and options overrides the parsed values with the options" do
      subject.connection_info(
        "amqp://user:password@host:1234/vhost",
        user:     "foo",
        password: "bar",
        port:     5678,
        ssl:      true
      ).should eq(
        user:     "foo",
        password: "bar",
        host:     "host",
        vhost:    "vhost",
        port:     5678,
        ssl:      true
      )
    end
  end
end
