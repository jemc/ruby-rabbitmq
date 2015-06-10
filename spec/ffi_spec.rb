
require 'spec_helper'


describe RabbitMQ::FFI do
  it { should be }
  
  its(:amqp_version) { should be_a String }
  
  describe "BasicProperties#to_h" do
    subject { RabbitMQ::FFI::BasicProperties.new }
    
    it "avoids a field if not seen in the _flags bitfield" do
      bad_bytes = RabbitMQ::FFI::Bytes.new
      bad_bytes[:len] = 99999999999
      bad_bytes[:bytes] = ::FFI::Pointer.new(0)
      
      subject[:_flags] = 0
      subject[:content_type] = bad_bytes
      
      result = subject.to_h
      result.key?(:content_type).should_not be
    end
    
    it "reads a field if seen in the _flags bitfield" do
      good_bytes = RabbitMQ::FFI::Bytes.from_s("application/json")
      
      subject[:_flags] = RabbitMQ::FFI::BasicProperties::FLAGS[:content_type]
      subject[:content_type] = good_bytes
      
      result = subject.to_h
      result[:content_type].should eq "application/json"
      
      good_bytes.free!
    end
  end
  
  describe "BasicProperties#apply" do
    subject { RabbitMQ::FFI::BasicProperties.new }
    
    it "sets the _flags bitfield for applied properties" do
      good_bytes = RabbitMQ::FFI::Bytes.from_s("application/json")
      flag_bit = RabbitMQ::FFI::BasicProperties::FLAGS[:content_type]
      
      (subject[:_flags] & flag_bit).should eq 0
      
      subject.apply(content_type: good_bytes)
      
      (subject[:_flags] & flag_bit).should_not eq 0
      subject[:content_type].to_s.should eq "application/json"
      
      good_bytes.free!
    end
  end
end
