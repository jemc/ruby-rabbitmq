
module RabbitMQ
  module FFI
    class BasicGetOk < ::FFI::Struct
      layout(
        :delivery_tag, :uint64,
        :redelivered, Boolean,
        :exchange, Bytes,
        :routing_key, Bytes,
        :message_count, :uint32
      )
      
      def self.id
        :basic_get_ok
      end
      
      def id
        :basic_get_ok
      end
      
      def apply(delivery_tag: nil, redelivered: nil, exchange: nil, routing_key: nil, message_count: nil)
        self[:delivery_tag] = Integer(delivery_tag) if delivery_tag
        self[:redelivered] = redelivered unless redelivered.nil?
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self[:message_count] = Integer(message_count) if message_count
        self
      end
      
      def to_h(free=false)
        {
          delivery_tag: self[:delivery_tag],
          redelivered: self[:redelivered],
          exchange: self[:exchange].to_s(free),
          routing_key: self[:routing_key].to_s(free),
          message_count: self[:message_count]
        }
      end
      
      def free!
        self[:exchange].free!
        self[:routing_key].free!
      end
      
    end
  end
end
