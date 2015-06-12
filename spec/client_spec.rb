
require 'spec_helper'


describe RabbitMQ::Client do
  let(:subject_class) { RabbitMQ::Client }
  let(:connection) { subject.instance_variable_get(:@conn) }
  
  describe "start" do
    it "calls Connection#start" do
      connection.should_receive(:start)
      subject.start
    end
    
    it "returns self" do
      subject.start.should eq subject
    end
  end
  
  describe "destroy" do
    it "calls Connection#destroy" do
      connection.should_receive(:destroy)
      subject.destroy
    end
    
    it "returns self" do
      subject.destroy.should eq subject
    end
  end
  
  describe "close" do
    it "calls Connection#close" do
      connection.should_receive(:close)
      subject.close
    end
    
    it "returns self" do
      subject.close.should eq subject
    end
  end
  
  describe "delegated connection properties" do
    let(:options) {{
      user:           "user",
      password:       "password",
      host:           "host",
      vhost:          "vhost",
      port:           1234,
      ssl:            false,
      max_channels:   100,
      max_frame_size: 9999,
    }}
    before { connection.should_receive(:options) { options } }
    
    its(:user)           { should eq options[:user] }
    its(:password)       { should eq options[:password] }
    its(:host)           { should eq options[:host] }
    its(:vhost)          { should eq options[:vhost] }
    its(:port)           { should eq options[:port] }
    its(:ssl?)           { should eq options[:ssl] }
    its(:max_channels)   { should eq options[:max_channels] }
    its(:max_frame_size) { should eq options[:max_frame_size] }
  end
  
  describe "channel" do
    before { subject.start }
    
    it "allocates id numbers in sequential ascending order" do
      channels = 100.times.map { subject.channel }
      channels.each_with_index { |c,i| c.id.should eq i+1 }
    end
    
    it "allocates slots from released channels when available" do
      channels = 100.times.map { subject.channel }
      channels.each_with_index { |c,i| c.id.should eq i+1 }
      
      20.times do
        channels.shuffle!
        channel = channels.pop
        id = channel.id
        channel.release
        channel = subject.channel
        channels.push channel
        channel.id.should eq id
      end
      
      subject.channel.id.should eq 101
    end
    
    it "raises an ArgumentError when there are no more channels available" do
      subject = subject_class.new(max_channels: 100).start
      subject.max_channels.should eq 100
      channels = 100.times.map { subject.channel }
      expect { subject.channel }.to raise_error ArgumentError, /too high/
    end
  end
  
  it "closes itself from server-sent connection error closure" do
    # Start the connection and the channel
    subject.start
    subject.send_request(11, :channel_open)
    subject.fetch_response(11, :channel_open_ok)
    
    # Try to open the same channel again - causes a connection error
    expect {
      subject.send_request(11, :channel_open)
      subject.fetch_response(11, :channel_open_ok)
    }.to raise_error RabbitMQ::ServerError::ConnectionError::CommandInvalid
    
    # Recover the connection and the channel
    subject.start
    subject.send_request(11, :channel_open)
    subject.fetch_response(11, :channel_open_ok)
  end
  
  describe "register_handler" do
    before { subject.start }
    let(:bucket) { [] }
    
    it "requires a block or callable to be given as the handler" do
      expect { subject.on_event(11, :channel_open_ok) }.to \
        raise_error ArgumentError, /block or callable/
    end
    
    shared_examples "handling events" do
      it "calls the handler for uncaught events" do
        subject.send_request(11, :channel_open)
        subject.run_loop!
        
        bucket.should_not be_empty
        event = bucket.pop
        event.fetch(:method).should eq :channel_open_ok
        event.fetch(:channel).should eq 11
        bucket.should be_empty
      end
      
      it "calls the handler for an caught events" do
        subject.on_event(11, :channel_open_ok) do |event|
          bucket << event
          subject.break!
        end
        
        subject.send_request(11, :channel_open)
        subject.fetch_response(11, :channel_open_ok)
        
        bucket.should_not be_empty
        event = bucket.pop
        event.fetch(:method).should eq :channel_open_ok
        event.fetch(:channel).should eq 11
        bucket.should be_empty
      end
      
      it "tolerates unecessary/nonsensical calls to break!" do
        subject.break!
        subject.break!
        
        subject.send_request(11, :channel_open)
        subject.run_loop!
        
        bucket.should_not be_empty
        event = bucket.pop
        event.fetch(:method).should eq :channel_open_ok
        event.fetch(:channel).should eq 11
        bucket.should be_empty
      end
      
      it "calls the event multiple times" do
        subject.break!
        subject.break!
        
        subject.send_request(11, :channel_open)
        subject.run_loop!
        
        4.times do
          subject.send_request(11, :channel_close)
          subject.fetch_response(11, :channel_close_ok)
          subject.send_request(11, :channel_open)
          subject.run_loop!
        end
        
        bucket.should_not be_empty
        5.times do
          event = bucket.pop
          event.fetch(:method).should eq :channel_open_ok
          event.fetch(:channel).should eq 11
        end
        bucket.should be_empty
      end
    end
    
    context "when given a block handler" do
      before do
        subject.on_event(11, :channel_open_ok) do |event|
          bucket << event
          subject.break!
        end
      end
      
      include_examples "handling events"
    end
      
    context "when given a callable handler" do
      before do
        subject, bucket = subject(), bucket()
        callable = Object.new
        callable.define_singleton_method(:call) do |event|
          bucket << event
          subject.break!
        end
        subject.on_event(11, :channel_open_ok, callable)
      end
      
      include_examples "handling events"
    end
  end
end
