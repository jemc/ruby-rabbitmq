
module RabbitMQ
  module FFI
    class ConnectionUnblocked < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :connection_unblocked
      end
      
      def id
        :connection_unblocked
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
