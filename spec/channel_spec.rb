
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
  
end
