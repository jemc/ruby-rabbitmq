
module RabbitMQ
  module FFI
    class ConnectionCloseOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :connection_close_ok
      end
      
      def id
        :connection_close_ok
      end
      
      def apply(dummy: nil)
        self
      end
      
      def to_h(free=false)
        {}
      end
      
      def free!
      end
      
    end
  end
end
