
module RabbitMQ
  module FFI
    class ExchangeDeleteOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :exchange_delete_ok
      end
      
      def id
        :exchange_delete_ok
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
