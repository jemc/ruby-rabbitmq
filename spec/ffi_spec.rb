
require 'spec_helper'


describe RabbitMQ::FFI do
  it { should be }
  it { should be_available }
  
  its(:amqp_version) { should be_a String }
end
