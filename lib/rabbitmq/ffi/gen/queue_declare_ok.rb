
module RabbitMQ
  module FFI
    class QueueDeclareOk < ::FFI::Struct
      layout(
        :queue, Bytes,
        :message_count, :uint32,
        :consumer_count, :uint32
      )
      
      def self.id
        :queue_declare_ok
      end
      
      def id
        :queue_declare_ok
      end
      
      def apply(queue: nil, message_count: nil, consumer_count: nil)
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:message_count] = Integer(message_count) if message_count
        self[:consumer_count] = Integer(consumer_count) if consumer_count
        self
      end
      
      def to_h(free=false)
        {
          queue: self[:queue].to_s(free),
          message_count: self[:message_count],
          consumer_count: self[:consumer_count]
        }
      end
      
      def free!
        self[:queue].free!
      end
      
    end
  end
end
