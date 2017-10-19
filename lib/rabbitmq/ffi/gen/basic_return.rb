
module RabbitMQ
  module FFI
    class BasicReturn < ::FFI::Struct
      layout(
        :reply_code, :uint16,
        :reply_text, Bytes,
        :exchange, Bytes,
        :routing_key, Bytes
      )
      
      def self.id
        :basic_return
      end
      
      def id
        :basic_return
      end
      
      def apply(reply_code: nil, reply_text: nil, exchange: nil, routing_key: nil)
        self[:reply_code] = Integer(reply_code) if reply_code
        self[:reply_text] = Bytes.from_s(reply_text.to_s) if reply_text
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self
      end
      
      def to_h(free=false)
        {
          reply_code: self[:reply_code],
          reply_text: self[:reply_text].to_s(free),
          exchange: self[:exchange].to_s(free),
          routing_key: self[:routing_key].to_s(free)
        }
      end
      
      def free!
        self[:reply_text].free!
        self[:exchange].free!
        self[:routing_key].free!
      end
      
    end
  end
end
