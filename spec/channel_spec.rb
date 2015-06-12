
require 'spec_helper'


describe RabbitMQ::Channel do
  let(:client) { RabbitMQ::Client.new.start }
  let(:id) { 11 }
  let(:subject) { client.channel(id) }
  
  it { should be_a RabbitMQ::Channel }
  
  its(:client) { should eq client }
  its(:id)     { should eq id }
  
  let(:max_id) { RabbitMQ::FFI::CHANNEL_MAX_ID }
  
  it "cannot be created if the given channel id is already allocated" do
    subject
    expect { client.channel(id) }.to \
      raise_error ArgumentError, /already in use/
    expect { client.channel(id) }.to \
      raise_error ArgumentError, /already in use/
  end
  
  it "cannot be created if the given channel id is too high" do
    client.channel(max_id)
    expect { client.channel(max_id + 1) }.to \
      raise_error ArgumentError, /too high/
  end
  
  it "cannot be created if a non-integer is given for its id" do
    expect { client.channel(Object.new) }.to \
      raise_error TypeError, /Integer/
  end
  
  describe "release" do
    it "releases the channel to be allocated again" do
      subject.release
      subject = client.channel(id)
      subject.release
      subject = client.channel(id)
    end
    
    it "can be called several times to no additional effect" do
      subject.release
      subject.release
      subject.release
    end
    
    it "returns self" do
      subject.release.should eq subject
    end
  end
  
  describe "delegating methods" do
    let(:a) { [1,2,3] }
    let(:b) { Proc.new { } }
    let(:res) { 88 }
    
    before { subject }
    
    specify "#on_event" do
      client.should_receive(:on_event).with(id, *a) { |*,&blk| blk.should eq b; res }
      subject.on_event(*a, &b).should eq res
    end
    
    specify "#on" do
      client.should_receive(:on_event).with(id, *a) { |*,&blk| blk.should eq b; res }
      subject.on(*a, &b).should eq res
    end
    
    specify "#send_request" do
      client.should_receive(:send_request).with(id, *a) { res }
      subject.send_request(*a).should eq res
    end
    
    specify "#fetch_response" do
      client.should_receive(:fetch_response).with(id, *a) { res }
      subject.fetch_response(*a).should eq res
    end
    
    specify "#run_loop!" do
      client.should_receive(:run_loop!).with(*a) { |*,&blk| blk.should eq b; res }
      subject.run_loop!(*a, &b).should eq res
    end
    
    specify "#break!" do
      client.should_receive(:break!) { res }
      subject.break!.should eq res
    end
  end
  
  it "can perform exchange operations" do
    res = subject.exchange_delete("my_exchange")
    res[:properties].should be_empty
    res = subject.exchange_delete("my_other_exchange")
    res[:properties].should be_empty
    
    res = subject.exchange_declare("my_exchange", "direct", durable: true)
    res[:properties].should be_empty
    res = subject.exchange_declare("my_other_exchange", "topic", durable: true)
    res[:properties].should be_empty
    
    res = subject.exchange_bind("my_exchange", "my_other_exchange", routing_key: "my_key")
    res[:properties].should be_empty
    
    res = subject.exchange_unbind("my_exchange", "my_other_exchange", routing_key: "my_key")
    res[:properties].should be_empty
    
    res = subject.exchange_delete("my_exchange", if_unused: true)
    res[:properties].should be_empty
    res = subject.exchange_delete("my_other_exchange", if_unused: true)
    res[:properties].should be_empty
  end
  
  it "can perform queue operations" do
    subject.exchange_delete("my_exchange")
    subject.exchange_declare("my_exchange", "direct", durable: true)
    
    res = subject.queue_delete("my_queue")
    res[:properties].delete(:message_count).should be_an Integer
    res[:properties].should be_empty
    
    res = subject.queue_declare("my_queue", durable: true)
    res[:properties].delete(:queue)         .should eq "my_queue"
    res[:properties].delete(:message_count) .should be_an Integer
    res[:properties].delete(:consumer_count).should be_an Integer
    res[:properties].should be_empty
    
    res = subject.queue_bind("my_queue", "my_exchange", routing_key: "my_key")
    res[:properties].should be_empty
    res = subject.queue_unbind("my_queue", "my_exchange", routing_key: "my_key")
    res[:properties].should be_empty
    
    res = subject.queue_purge("my_queue")
    res[:properties].delete(:message_count).should be_an Integer
    res[:properties].should be_empty
    
    res = subject.queue_delete("my_queue", if_unused: true)
    res[:properties].delete(:message_count).should be_an Integer
    res[:properties].should be_empty
  end
  
  it "can perform consumer operations" do
    subject.queue_delete("my_queue")
    subject.queue_declare("my_queue")
    
    res = subject.basic_qos(prefetch_count: 10, global: true)
    res[:properties].should be_empty
    
    tag = "my_consumer"
    res = subject.basic_consume("my_queue", tag, exclusive: true)
    res[:properties].delete(:consumer_tag).should eq tag
    res[:properties].should be_empty
    
    res = subject.basic_cancel(tag)
    res[:properties].delete(:consumer_tag).should eq tag
    res[:properties].should be_empty
    
    res = subject.basic_consume("my_queue")
    tag = res[:properties].delete(:consumer_tag)
    tag.should be_a String; tag.should_not be_empty
    res[:properties].should be_empty
    
    res = subject.basic_cancel(tag)
    res[:properties].delete(:consumer_tag).should eq tag
    res[:properties].should be_empty
  end
  
  it "can perform transaction operations" do
    res = subject.tx_select
    res[:properties].should be_empty
    subject.queue_delete("my_queue")
    subject.queue_declare("my_queue")
    res = subject.tx_rollback
    res[:properties].should be_empty
    
    res = subject.tx_select
    res[:properties].should be_empty
    subject.queue_delete("my_queue")
    subject.queue_declare("my_queue")
    res = subject.tx_commit
    res[:properties].should be_empty
  end
  
  it "can perform message operations" do
    subject.queue_delete("my_queue")
    subject.queue_declare("my_queue")
    
    res = subject.basic_publish("message_body", "", "my_queue",
                                persistent: true, priority: 5)
    res.should eq true
    
    res = subject.basic_get("my_queue", no_ack: true)
    res[:method].should eq :basic_get_ok
    res[:properties].delete(:delivery_tag) .should be_an Integer
    res[:properties].delete(:redelivered)  .should eq false
    res[:properties].delete(:exchange)     .should eq ""
    res[:properties].delete(:routing_key)  .should eq "my_queue"
    res[:properties].delete(:message_count).should eq 0
    res[:properties].should be_empty
    res[:header].should be_a Hash
    res[:body].should eq "message_body"
    
    res = subject.basic_get("my_queue", no_ack: true)
    res[:method].should eq :basic_get_empty
    res[:properties].delete(:cluster_id).should be_a String
    res[:properties].should be_empty
    res.has_key?(:header).should_not be
    res.has_key?(:body).should_not be
  end
  
  it "can consume messages from basic_deliver" do
    subject.queue_delete("my_queue")
    subject.queue_declare("my_queue")
    
    # Publish some messages to the queue
    10.times do |i|
      subject.basic_publish("message_#{i}", "", "my_queue")
    end
    
    # Negotiate this channel as a consumer of the queue
    res = subject.basic_consume("my_queue", exclusive: false)
    res[:method].should eq :basic_consume_ok
    
    # Set up a handler to consume and test the messages delivered
    counter = 0
    subject.on :basic_deliver do |res|
      consumer_tag = res[:properties].delete(:consumer_tag)
      consumer_tag.should be_a String; consumer_tag.should_not be_empty
      
      delivery_tag = res[:properties].delete(:delivery_tag)
      delivery_tag.should be_an Integer
      
      res[:method].should eq :basic_deliver
      res[:properties].delete(:redelivered).should eq false
      res[:properties].delete(:exchange)   .should eq ""
      res[:properties].delete(:routing_key).should eq "my_queue"
      res[:properties].should be_empty
      res[:header].should be_a Hash
      res[:body].should eq "message_#{counter}"
      
      # Test a mixture of the acknowledgement types
      res = if counter.odd?
        subject.basic_ack(delivery_tag, multiple: false)
      elsif (counter/2).odd?
        subject.basic_nack(delivery_tag, multiple: false, requeue: false)
      else
        subject.basic_reject(delivery_tag, requeue: false)
      end
      res.should eq true
      
      subject.break! if (counter += 1) == 10
    end
    
    # Run the event loop to actually consume all messages
    subject.run_loop!
    counter.should eq 10
  end
  
  it "can recover from server-sent channel error closure" do
    subject.queue_delete("my_queue")
    
    10.times do
      expect { subject.queue_purge("my_queue") }.to \
        raise_error RabbitMQ::ServerError::ChannelError::NotFound
    end
    
    subject.queue_delete("my_queue")
  end
  
end
