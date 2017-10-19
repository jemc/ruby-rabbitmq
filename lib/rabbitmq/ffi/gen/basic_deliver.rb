
module RabbitMQ
  module FFI
    class BasicDeliver < ::FFI::Struct
      layout(
        :consumer_tag, Bytes,
        :delivery_tag, :uint64,
        :redelivered, Boolean,
        :exchange, Bytes,
        :routing_key, Bytes
      )
      
      def self.id
        :basic_deliver
      end
      
      def id
        :basic_deliver
      end
      
      def apply(consumer_tag: nil, delivery_tag: nil, redelivered: nil, exchange: nil, routing_key: nil)
        self[:consumer_tag] = Bytes.from_s(consumer_tag.to_s) if consumer_tag
        self[:delivery_tag] = Integer(delivery_tag) if delivery_tag
        self[:redelivered] = redelivered unless redelivered.nil?
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self
      end
      
      def to_h(free=false)
        {
          consumer_tag: self[:consumer_tag].to_s(free),
          delivery_tag: self[:delivery_tag],
          redelivered: self[:redelivered],
          exchange: self[:exchange].to_s(free),
          routing_key: self[:routing_key].to_s(free)
        }
      end
      
      def free!
        self[:consumer_tag].free!
        self[:exchange].free!
        self[:routing_key].free!
      end
      
    end
  end
end
