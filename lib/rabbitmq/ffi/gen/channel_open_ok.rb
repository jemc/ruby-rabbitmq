
module RabbitMQ
  module FFI
    class ChannelOpenOk < ::FFI::Struct
      layout(:channel_id, Bytes)
      
      def self.id
        :channel_open_ok
      end
      
      def id
        :channel_open_ok
      end
      
      def apply(channel_id: nil)
        self[:channel_id] = Bytes.from_s(channel_id.to_s) if channel_id
        self
      end
      
      def to_h(free=false)
        {channel_id: self[:channel_id].to_s(free)}
      end
      
      def free!
        self[:channel_id].free!
      end
      
    end
  end
end
