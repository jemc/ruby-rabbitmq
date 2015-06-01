
require 'spec_helper'


describe RabbitMQ::Connection do
  let(:subject_class) { RabbitMQ::Connection }
  
  describe "destroy" do
    it "is not necessary to call" do
      subject
    end
    
    it "can be called several times to no additional effect" do
      subject.destroy
      subject.destroy
      subject.destroy
    end
    
    it "prevents any other network operations on the object" do
      subject.destroy
      expect { subject.start }.to raise_error RabbitMQ::Connection::DestroyedError
      expect { subject.close }.to raise_error RabbitMQ::Connection::DestroyedError
    end
  end
  
  describe "start" do
    it "initiates the connection to the server" do
      subject.start
    end
    
    it "can be called several times to reconnect" do
      subject.start
      subject.start
      subject.start
    end
    
    it "returns self" do
      subject.start.should eq subject
    end
  end
  
  describe "close" do
    it "closes the initiated connection" do
      subject.start
      subject.close
    end
    
    it "can be called several times to no additional effect" do
      subject.start
      subject.close
      subject.close
      subject.close
    end
    
    it "can be called before connecting to no effect" do
      subject.close
    end
    
    it "returns self" do
      subject.close.should eq subject
    end
  end
  
  it "uses Util.connection_info to parse info from its creation arguments" do
    args = ["parsable url", { foo: "bar" }]
    RabbitMQ::Util.should_receive(:connection_info).with(*args) {{
      user:     "user",
      password: "password",
      host:     "host",
      vhost:    "vhost",
      port:     1234,
      ssl:      false
    }}
    subject = subject_class.new(*args)
    
    subject.user    .should eq "user"
    subject.password.should eq "password"
    subject.host    .should eq "host"
    subject.vhost   .should eq "vhost"
    subject.port    .should eq 1234
    subject.ssl?    .should eq false
  end
end
