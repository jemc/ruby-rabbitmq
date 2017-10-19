
module RabbitMQ
  module FFI
    class QueueBindOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :queue_bind_ok
      end
      
      def id
        :queue_bind_ok
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
