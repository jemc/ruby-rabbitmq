
module RabbitMQ
  module FFI
    class TxRollback < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :tx_rollback
      end
      
      def id
        :tx_rollback
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
