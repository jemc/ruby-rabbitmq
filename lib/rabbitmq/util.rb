
class RabbitMQ::FFI::Error < RuntimeError; end

module RabbitMQ
  module Util; end
  class << Util
    
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
    
    def connection_info url=nil
      info = FFI::ConnectionInfo.new
      
      if url
        url_ptr = Util.strdup_ptr(url)
        Util.error_check :"parsing connection URL",
          FFI.amqp_parse_url(url_ptr, info)
        
        # We must copy ConnectionInfo before the url_ptr is freed.
        result = info.to_h
        url_ptr.free
        result
      else
        FFI.amqp_default_connection_info(info)
        info.to_h
      end
    end
    
  end
end
