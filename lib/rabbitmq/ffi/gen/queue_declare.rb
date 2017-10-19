
module RabbitMQ
  module FFI
    class QueueDeclare < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :passive, Boolean,
        :durable, Boolean,
        :exclusive, Boolean,
        :auto_delete, Boolean,
        :nowait, Boolean,
        :arguments, Table
      )
      
      def self.id
        :queue_declare
      end
      
      def id
        :queue_declare
      end
      
      def apply(ticket: nil, queue: nil, passive: nil, durable: nil, exclusive: nil, auto_delete: nil, nowait: nil, arguments: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:passive] = passive unless passive.nil?
        self[:durable] = durable unless durable.nil?
        self[:exclusive] = exclusive unless exclusive.nil?
        self[:auto_delete] = auto_delete unless auto_delete.nil?
        self[:nowait] = nowait unless nowait.nil?
        self[:arguments] = Table.from(arguments) if arguments
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          passive: self[:passive],
          durable: self[:durable],
          exclusive: self[:exclusive],
          auto_delete: self[:auto_delete],
          nowait: self[:nowait],
          arguments: self[:arguments].to_h(free)
        }
      end
      
      def free!
        self[:queue].free!
        self[:arguments].free!
      end
      
    end
  end
end
