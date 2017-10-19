
module RabbitMQ
  module FFI
    class BasicRecoverOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :basic_recover_ok
      end
      
      def id
        :basic_recover_ok
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
