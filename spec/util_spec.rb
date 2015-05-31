
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
end
