
module RabbitMQ
  module FFI
    class BasicNack < ::FFI::Struct
      layout(
        :delivery_tag, :uint64,
        :multiple, Boolean,
        :requeue, Boolean
      )
      
      def self.id
        :basic_nack
      end
      
      def id
        :basic_nack
      end
      
      def apply(delivery_tag: nil, multiple: nil, requeue: nil)
        self[:delivery_tag] = Integer(delivery_tag) if delivery_tag
        self[:multiple] = multiple unless multiple.nil?
        self[:requeue] = requeue unless requeue.nil?
        self
      end
      
      def to_h(free=false)
        {
          delivery_tag: self[:delivery_tag],
          multiple: self[:multiple],
          requeue: self[:requeue]
        }
      end
      
      def free!
      end
      
    end
  end
end
