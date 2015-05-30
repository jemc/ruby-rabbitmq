
class RabbitMQ::FFI::Error < RuntimeError; end

module RabbitMQ::Util
  class << self
    
    def error_check rc=nil
      rc ||= yield
      return if rc == 0
      raise RabbitMQ::FFI::Error, RabbitMQ::FFI.amqp_error_string2(rc)
    end
    
  end
end
