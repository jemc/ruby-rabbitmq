
module RabbitMQ
  module FFI
    class ExchangeDelete < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :exchange, Bytes,
        :if_unused, Boolean,
        :nowait, Boolean
      )
      
      def self.id
        :exchange_delete
      end
      
      def id
        :exchange_delete
      end
      
      def apply(ticket: nil, exchange: nil, if_unused: nil, nowait: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:if_unused] = if_unused unless if_unused.nil?
        self[:nowait] = nowait unless nowait.nil?
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          exchange: self[:exchange].to_s(free),
          if_unused: self[:if_unused],
          nowait: self[:nowait]
        }
      end
      
      def free!
        self[:exchange].free!
      end
      
    end
  end
end
