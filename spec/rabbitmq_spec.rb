
require 'spec_helper'


describe RabbitMQ do
  describe "DEFAULT_EXCHANGE" do
    subject { RabbitMQ::DEFAULT_EXCHANGE }
    
    it { should eq "" }
  end
  
  describe "AVAILABILITY_ERRORS" do
    subject { RabbitMQ::AVAILABILITY_ERRORS }
    
    it { should be_an Array }
    it { should_not be_empty }
    
    specify "each element is a subclass of Exception" do
      subject.all? { |e| e < Exception }.should be true
    end
  end
end
