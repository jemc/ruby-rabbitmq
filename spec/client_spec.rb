
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
    let(:other_bucket) { [] }
    
    it "requires a block or callable object to be given as the handler" do
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
      
      it "clears the handler when another one is registered" do
        subject.on_event(11, :channel_open_ok) do |event|
          other_bucket << event
          subject.break!
        end
        
        subject.send_request(11, :channel_open)
        subject.fetch_response(11, :channel_open_ok)
        
        bucket.should be_empty
        other_bucket.should_not be_empty
        event = other_bucket.pop
        event.fetch(:method).should eq :channel_open_ok
        event.fetch(:channel).should eq 11
        other_bucket.should be_empty
      end
      
      it "clears the handler when explicitly unregistered" do
        subject.clear_event_handler(11, :channel_open_ok).should respond_to :call
        
        subject.send_request(11, :channel_open)
        subject.fetch_response(11, :channel_open_ok)
        
        bucket.should be_empty
      end
      
      it "clears the handler and returns nil when already cleared" do
        subject.clear_event_handler(11, :channel_close_ok).should eq nil
        
        subject.clear_event_handler(11, :channel_open_ok).should respond_to :call
        subject.clear_event_handler(11, :channel_open_ok).should eq nil
      end
      
      it "calls the block passed to run_loop! for handler-matching events" do
        subject.send_request(11, :channel_open)
        subject.run_loop! do |event|
          other_bucket << event
          subject.break!
        end
        
        bucket.should eq other_bucket
        other_bucket.should_not be_empty
        event = other_bucket.pop
        event.fetch(:method).should eq :channel_open_ok
        event.fetch(:channel).should eq 11
        other_bucket.should be_empty
      end
      
      it "calls the block passed to run_loop! for non-handler-matching events" do
        subject.send_request(11, :channel_open)
        subject.fetch_response(11, :channel_open_ok)
        bucket.pop
        
        subject.send_request(11, :channel_close)
        subject.run_loop! do |event|
          other_bucket << event
          subject.break!
        end
        
        bucket.should be_empty
        other_bucket.should_not be_empty
        event = other_bucket.pop
        event.fetch(:method).should eq :channel_close_ok
        event.fetch(:channel).should eq 11
        other_bucket.should be_empty
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
    
    context "with a block registered as an event handler" do
      before do
        subject.on_event(11, :channel_open_ok) do |event|
          bucket << event
          subject.break!
        end
      end
      
      include_examples "handling events"
    end
    
    context "with a callable object registered as an event handler" do
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
    
    describe "timeout" do
      def assert_time_elapsed(less_than: nil, greater_than: nil)
        start = Time.now
        yield
      ensure
        time = Time.now - start
        time.should be < less_than    if less_than
        time.should be > greater_than if greater_than
      end
      
      def with_test_timeout(timeout)
        main = Thread.current
        Thread.new { sleep timeout; main.raise(RuntimeError, "test timeout") }
        yield
      rescue RuntimeError => e
        e.message.should eq "test timeout"
      end
      
      specify "of zero passed to run_loop!" do
        assert_time_elapsed less_than: 0.25 do
          subject.run_loop! timeout: 0 do
            assert nil, "This block should never be run"
          end
        end
      end
      
      specify "of zero passed to fetch_response" do
        expect {
          assert_time_elapsed less_than: 0.25 do
            subject.fetch_response(11, :channel_open_ok, timeout: 0)
          end
        }.to raise_error RabbitMQ::FFI::Error::Timeout
      end
      
      specify "of 0.25 passed to run_loop!" do
        assert_time_elapsed greater_than: 0.25 do
          subject.run_loop! timeout: 0.25 do
            assert nil, "This block should never be run"
          end
        end
      end
      
      specify "of 0.25 passed to fetch_response" do
        expect {
          assert_time_elapsed greater_than: 0.25 do
            subject.fetch_response(11, :channel_open_ok, timeout: 0.25)
          end
        }.to raise_error RabbitMQ::FFI::Error::Timeout
      end
      
      specify "of nil passed to run_loop!" do
        with_test_timeout 0.25 do
          assert_time_elapsed greater_than: 0.2 do
            subject.run_loop! timeout: nil do
              assert nil, "This block should never be run"
            end
          end
        end
      end
      
      specify "of nil passed to fetch_response" do
        with_test_timeout 0.25 do
          assert_time_elapsed greater_than: 0.2 do
            subject.fetch_response(11, :channel_open_ok, timeout: nil)
          end
        end
      end
    end
    
  end
end
