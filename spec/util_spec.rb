
require 'spec_helper'


describe RabbitMQ::Util do
  it { should be }
  
  describe "error_check" do
    it "returns nil when given a zero result code" do
      subject.error_check(:foo, 0).should eq nil
    end
    
    it "raises an error when given a nonzero result code" do
      expect { subject.error_check(:foo, -1) }.to \
        raise_error RabbitMQ::FFI::Error, /foo/
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
