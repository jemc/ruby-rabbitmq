
module RabbitMQ
  module FFI
    class ChannelFlow < ::FFI::Struct
      layout(:active, Boolean)
      
      def self.id
        :channel_flow
      end
      
      def id
        :channel_flow
      end
      
      def apply(active: nil)
        self[:active] = active unless active.nil?
        self
      end
      
      def to_h(free=false)
        {active: self[:active]}
      end
      
      def free!
      end
      
    end
  end
end
