
module RabbitMQ
  module FFI
    class ExchangeUnbindOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :exchange_unbind_ok
      end
      
      def id
        :exchange_unbind_ok
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
