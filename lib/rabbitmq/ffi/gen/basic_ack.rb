
module RabbitMQ
  module FFI
    class BasicAck < ::FFI::Struct
      layout(
        :delivery_tag, :uint64,
        :multiple, Boolean
      )
      
      def self.id
        :basic_ack
      end
      
      def id
        :basic_ack
      end
      
      def apply(delivery_tag: nil, multiple: nil)
        self[:delivery_tag] = Integer(delivery_tag) if delivery_tag
        self[:multiple] = multiple unless multiple.nil?
        self
      end
      
      def to_h(free=false)
        {
          delivery_tag: self[:delivery_tag],
          multiple: self[:multiple]
        }
      end
      
      def free!
      end
      
    end
  end
end
