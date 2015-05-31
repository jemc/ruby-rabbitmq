
class RabbitMQ::FFI::Error < RuntimeError; end

module RabbitMQ::Util
  class << self
    
    def raise_error! message="unspecified error", action=nil
      message = "while #{action} - #{message}" if action
      raise RabbitMQ::FFI::Error, message.to_s
    end
    
    def error_check action, rc
      return if rc == 0
      raise_error! RabbitMQ::FFI.amqp_error_string2(rc), action
    end
    
    def null_check action, obj
      return unless obj.nil?
      raise_error! "got unexpected null", action
    end
    
    def mem_ptr size, count: 1, clear: true, release: true
      ptr = ::FFI::MemoryPointer.new(size, count, clear)
      ptr.autorelease = false unless release
      ptr
    end
    
    def arg_ptr type, **kwargs
      type = ::FFI::TypeDefs[type] if type.is_a?(Symbol)
      mem_ptr(type.size, clear: false, **kwargs)
    end
    
    def strdup_ptr str, **kwargs
      str = str + "\x00"
      ptr = mem_ptr(str.bytesize, **kwargs)
      ptr.write_string(str)
      ptr
    end
    
  end
end
