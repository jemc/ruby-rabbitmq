
module RabbitMQ
  module FFI
    class BasicGet < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :no_ack, Boolean
      )
      
      def self.id
        :basic_get
      end
      
      def id
        :basic_get
      end
      
      def apply(ticket: nil, queue: nil, no_ack: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:no_ack] = no_ack unless no_ack.nil?
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          no_ack: self[:no_ack]
        }
      end
      
      def free!
        self[:queue].free!
      end
      
    end
  end
end
