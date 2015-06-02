
require 'spec_helper'


describe RabbitMQ::Channel do
  let(:subject_class) { RabbitMQ::Channel }
  let(:connection) { RabbitMQ::Connection.new.start }
  let(:id) { 11 }
  let(:subject) { subject_class.new(connection, id) }
  
  its(:connection) { should eq connection }
  its(:id)         { should eq id }
  
  let(:max_id) { RabbitMQ::FFI::CHANNEL_MAX_ID }
  
  it "cannot be created if the given channel id is already allocated" do
    subject
    expect { subject_class.new(connection, id) }.to \
      raise_error ArgumentError, /already in use/
    expect { subject_class.new(connection, id) }.to \
      raise_error ArgumentError, /already in use/
  end
  
  it "cannot be created if the given channel id is too high" do
    subject_class.new(connection, max_id)
    expect { subject_class.new(connection, max_id + 1) }.to \
      raise_error ArgumentError, /too high/
  end
  
  describe "release" do
    it "releases the channel to be allocated again" do
      subject.release
      subject = subject_class.new(connection, id)
      subject.release
      subject = subject_class.new(connection, id)
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
  
  it "can perform exchange operations" do
    res = subject.exchange_delete("my_exchange")
    res.should be_empty
    res = subject.exchange_delete("my_other_exchange")
    res.should be_empty
    
    res = subject.exchange_declare("my_exchange", "direct", durable: true)
    res.should be_empty
    res = subject.exchange_declare("my_other_exchange", "topic", durable: true)
    res.should be_empty
    
    res = subject.exchange_bind("my_exchange", "my_other_exchange", routing_key: "my_key")
    res.should be_empty
    
    res = subject.exchange_unbind("my_exchange", "my_other_exchange", routing_key: "my_key")
    res.should be_empty
    
    res = subject.exchange_delete("my_exchange", if_unused: true)
    res.should be_empty
    res = subject.exchange_delete("my_other_exchange", if_unused: true)
    res.should be_empty
  end
  
  it "can perform queue operations" do
    res = subject.exchange_delete("my_exchange")
    res = subject.exchange_declare("my_exchange", "direct", durable: true)
    
    res = subject.queue_delete("my_queue")
    res.delete(:message_count).should be_an Integer
    res.should be_empty
    
    res = subject.queue_declare("my_queue", durable: true)
    res.delete(:queue)         .should eq "my_queue"
    res.delete(:message_count) .should be_an Integer
    res.delete(:consumer_count).should be_an Integer
    res.should be_empty
    
    res = subject.queue_bind("my_queue", "my_exchange", routing_key: "my_key")
    res.should be_empty
    res = subject.queue_unbind("my_queue", "my_exchange", routing_key: "my_key")
    res.should be_empty
    
    res = subject.queue_purge("my_queue")
    res.delete(:message_count).should be_an Integer
    res.should be_empty
    
    res = subject.queue_delete("my_queue", if_unused: true)
    res.delete(:message_count).should be_an Integer
    res.should be_empty
  end
  
end
