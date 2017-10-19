
module RabbitMQ
  module FFI
    class TxSelect < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :tx_select
      end
      
      def id
        :tx_select
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
