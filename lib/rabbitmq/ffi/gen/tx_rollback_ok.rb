
module RabbitMQ
  module FFI
    class TxRollbackOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :tx_rollback_ok
      end
      
      def id
        :tx_rollback_ok
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
