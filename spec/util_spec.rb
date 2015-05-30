
require 'spec_helper'


describe RabbitMQ::Util do
  it { should be }
  
  describe "error_check" do
    it "returns nil when given a zero result code" do
      subject.error_check(0).should eq nil
    end
    
    it "raises an error when given a nonzero result code" do
      expect { subject.error_check(-1) }.to raise_error RabbitMQ::FFI::Error
    end
    
    it "returns nil when given a zero result code in a block" do
      subject.error_check { 0 }.should eq nil
    end
    
    it "raises an error when given a nonzero result code in a block" do
      expect { subject.error_check { -1 } }.to raise_error RabbitMQ::FFI::Error
    end
  end
end
