
module RabbitMQ
  module FFI
    class ExchangeBind < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :destination, Bytes,
        :source, Bytes,
        :routing_key, Bytes,
        :nowait, Boolean,
        :arguments, Table
      )
      
      def self.id
        :exchange_bind
      end
      
      def id
        :exchange_bind
      end
      
      def apply(ticket: nil, destination: nil, source: nil, routing_key: nil, nowait: nil, arguments: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:destination] = Bytes.from_s(destination.to_s) if destination
        self[:source] = Bytes.from_s(source.to_s) if source
        self[:routing_key] = Bytes.from_s(routing_key.to_s) if routing_key
        self[:nowait] = nowait unless nowait.nil?
        self[:arguments] = Table.from(arguments) if arguments
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          destination: self[:destination].to_s(free),
          source: self[:source].to_s(free),
          routing_key: self[:routing_key].to_s(free),
          nowait: self[:nowait],
          arguments: self[:arguments].to_h(free)
        }
      end
      
      def free!
        self[:destination].free!
        self[:source].free!
        self[:routing_key].free!
        self[:arguments].free!
      end
      
    end
  end
end
