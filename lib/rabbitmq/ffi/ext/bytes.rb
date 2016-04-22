
module RabbitMQ
  module FFI
    
    class Bytes
      def to_s(free=false)
        size = self[:len]
        s = size == 0 ? "" : self[:bytes].read_bytes(size)
        s.force_encoding(Encoding::ASCII_8BIT)
        free! if free
        s
      end
      
      def free!
        FFI.free(self[:bytes])
        clear
      end
      
      def self.from_s(str)
        size = str.bytesize
        bytes = FFI.amqp_bytes_malloc(size)
        
        bytes[:bytes].write_string(str)
        bytes[:len] = size
        bytes
      end
    end
    
  end
end
