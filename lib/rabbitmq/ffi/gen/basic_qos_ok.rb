
module RabbitMQ
  module FFI
    class BasicQosOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :basic_qos_ok
      end
      
      def id
        :basic_qos_ok
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
