
module RabbitMQ
  module FFI
    class ConfirmSelectOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :confirm_select_ok
      end
      
      def id
        :confirm_select_ok
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
