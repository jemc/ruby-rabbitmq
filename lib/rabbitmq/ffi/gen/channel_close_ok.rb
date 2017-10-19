
module RabbitMQ
  module FFI
    class ChannelCloseOk < ::FFI::Struct
      layout(:dummy, :char)
      
      def self.id
        :channel_close_ok
      end
      
      def id
        :channel_close_ok
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
