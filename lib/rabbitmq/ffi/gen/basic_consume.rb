
module RabbitMQ
  module FFI
    class BasicConsume < ::FFI::Struct
      layout(
        :ticket, :uint16,
        :queue, Bytes,
        :consumer_tag, Bytes,
        :no_local, Boolean,
        :no_ack, Boolean,
        :exclusive, Boolean,
        :nowait, Boolean,
        :arguments, Table
      )
      
      def self.id
        :basic_consume
      end
      
      def id
        :basic_consume
      end
      
      def apply(ticket: nil, queue: nil, consumer_tag: nil, no_local: nil, no_ack: nil, exclusive: nil, nowait: nil, arguments: nil)
        self[:ticket] = Integer(ticket) if ticket
        self[:queue] = Bytes.from_s(queue.to_s) if queue
        self[:consumer_tag] = Bytes.from_s(consumer_tag.to_s) if consumer_tag
        self[:no_local] = no_local unless no_local.nil?
        self[:no_ack] = no_ack unless no_ack.nil?
        self[:exclusive] = exclusive unless exclusive.nil?
        self[:nowait] = nowait unless nowait.nil?
        self[:arguments] = Table.from(arguments) if arguments
        self
      end
      
      def to_h(free=false)
        {
          ticket: self[:ticket],
          queue: self[:queue].to_s(free),
          consumer_tag: self[:consumer_tag].to_s(free),
          no_local: self[:no_local],
          no_ack: self[:no_ack],
          exclusive: self[:exclusive],
          nowait: self[:nowait],
          arguments: self[:arguments].to_h(free)
        }
      end
      
      def free!
        self[:queue].free!
        self[:consumer_tag].free!
        self[:arguments].free!
      end
      
    end
  end
end
