
module RabbitMQ
  module FFI
    class ExchangeDeclare < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :exchange, Bytes,
        :type, Bytes,
        :passive, Boolean,
        :durable, Boolean,
        :auto_delete, Boolean,
        :internal, Boolean,
        :nowait, Boolean,
        :arguments, Table
      )
      
      def self.id
        :exchange_declare
      end
      
      def id
        :exchange_declare
      end
      
      def apply(ticket: nil, exchange: nil, type: nil, passive: nil, durable: nil, auto_delete: nil, internal: nil, nowait: nil, arguments: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:exchange] = Bytes.from_s(exchange.to_s) if exchange
        self[:type] = Bytes.from_s(type.to_s) if type
        self[:passive] = passive unless passive.nil?
        self[:durable] = durable unless durable.nil?
        self[:auto_delete] = auto_delete unless auto_delete.nil?
        self[:internal] = internal unless internal.nil?
        self[:nowait] = nowait unless nowait.nil?
        self[:arguments] = Table.from(arguments) if arguments
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          exchange: self[:exchange].to_s(free),
          type: self[:type].to_s(free),
          passive: self[:passive],
          durable: self[:durable],
          auto_delete: self[:auto_delete],
          internal: self[:internal],
          nowait: self[:nowait],
          arguments: self[:arguments].to_h(free)
        }
      end
      
      def free!
        self[:exchange].free!
        self[:type].free!
        self[:arguments].free!
      end
      
    end
  end
end
