
module RabbitMQ
  module FFI
    class BasicPublish < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :exchange, Bytes,
        :routing_key, Bytes,
        :mandatory, Boolean,
        :immediate, Boolean
      )
      
      def self.id
        :basic_publish
      end
      
      def id
        :basic_publish
      end
      
      def apply(ticket: nil, exchange: nil, routing_key: nil, mandatory: nil, immediate: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self[:mandatory] = mandatory unless mandatory.nil?
        self[:immediate] = immediate unless immediate.nil?
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          exchange: self[:exchange].to_s(free),
          routing_key: self[:routing_key].to_s(free),
          mandatory: self[:mandatory],
          immediate: self[:immediate]
        }
      end
      
      def free!
        self[:exchange].free!
        self[:routing_key].free!
      end
      
    end
  end
end
