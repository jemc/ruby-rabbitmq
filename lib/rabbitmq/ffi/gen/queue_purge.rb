
module RabbitMQ
  module FFI
    class QueuePurge < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :nowait, Boolean
      )
      
      def self.id
        :queue_purge
      end
      
      def id
        :queue_purge
      end
      
      def apply(ticket: nil, queue: nil, nowait: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:nowait] = nowait unless nowait.nil?
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          nowait: self[:nowait]
        }
      end
      
      def free!
        self[:queue].free!
      end
      
    end
  end
end
