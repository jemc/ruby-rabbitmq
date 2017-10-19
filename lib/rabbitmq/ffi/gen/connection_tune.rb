
module RabbitMQ
  module FFI
    class ConnectionTune < ::FFI::Struct
      layout(
        :channel_max, :uint16,
        :frame_max, :uint32,
        :heartbeat, :uint16
      )
      
      def self.id
        :connection_tune
      end
      
      def id
        :connection_tune
      end
      
      def apply(channel_max: nil, frame_max: nil, heartbeat: nil)
        self[:channel_max] = Integer(channel_max) if channel_max
        self[:frame_max] = Integer(frame_max) if frame_max
        self[:heartbeat] = Integer(heartbeat) if heartbeat
        self
      end
      
      def to_h(free=false)
        {
          channel_max: self[:channel_max],
          frame_max: self[:frame_max],
          heartbeat: self[:heartbeat]
        }
      end
      
      def free!
      end
      
    end
  end
end
