
module RabbitMQ
  module FFI
    class TxCommit < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :tx_commit
      end
      
      def id
        :tx_commit
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
