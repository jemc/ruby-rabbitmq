
require 'spec_helper'


describe RabbitMQ::Channel do
  let(:subject_class) { RabbitMQ::Channel }
  let(:connection) { RabbitMQ::Connection.new.start }
  let(:id) { 11 }
  let(:subject) { subject_class.new(connection, id) }
  
  its(:connection) { should eq connection }
  its(:id)         { should eq id }
end
