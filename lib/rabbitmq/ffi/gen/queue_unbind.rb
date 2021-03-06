
module RabbitMQ
  module FFI
    class QueueUnbind < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :exchange, Bytes,
        :routing_key, Bytes,
        :arguments, Table
      )
      
      def self.id
        :queue_unbind
      end
      
      def id
        :queue_unbind
      end
      
      def apply(ticket: nil, queue: nil, exchange: nil, routing_key: nil, arguments: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self[:arguments] = Table.from(arguments) if arguments
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          exchange: self[:exchange].to_s(free),
          routing_key: self[:routing_key].to_s(free),
          arguments: self[:arguments].to_h(free)
        }
      end
      
      def free!
        self[:queue].free!
        self[:exchange].free!
        self[:routing_key].free!
        self[:arguments].free!
      end
      
    end
  end
end
