
module RabbitMQ
  module FFI
    class QueueDelete < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :if_unused, Boolean,
        :if_empty, Boolean,
        :nowait, Boolean
      )
      
      def self.id
        :queue_delete
      end
      
      def id
        :queue_delete
      end
      
      def apply(ticket: nil, queue: nil, if_unused: nil, if_empty: nil, nowait: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:if_unused] = if_unused unless if_unused.nil?
        self[:if_empty] = if_empty unless if_empty.nil?
        self[:nowait] = nowait unless nowait.nil?
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          if_unused: self[:if_unused],
          if_empty: self[:if_empty],
          nowait: self[:nowait]
        }
      end
      
      def free!
        self[:queue].free!
      end
      
    end
  end
end
