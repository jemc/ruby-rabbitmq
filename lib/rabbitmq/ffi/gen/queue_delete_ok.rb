
module RabbitMQ
  module FFI
    class QueueDeleteOk < ::FFI::Struct
      layout(:message_count, :uint32)
      
      def self.id
        :queue_delete_ok
      end
      
      def id
        :queue_delete_ok
      end
      
      def apply(message_count: nil)
        self[:message_count] = Integer(message_count) if message_count
        self
      end
      
      def to_h(free=false)
        {message_count: self[:message_count]}
      end
      
      def free!
      end
      
    end
  end
end
