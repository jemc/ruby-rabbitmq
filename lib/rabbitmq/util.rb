
class RabbitMQ::FFI::Error < RuntimeError; end

module RabbitMQ::Util
  class << self
    
    def error_check action, status
      return if status == :ok
      raise RabbitMQ::FFI::Error.lookup(status), "while #{action}"
    end
    
    def null_check action, obj
      return unless obj.nil?
      raise RabbitMQ::FFI::Error, "while #{action} - got unexpected null"
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
