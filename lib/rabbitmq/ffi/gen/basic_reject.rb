
module RabbitMQ
  module FFI
    class BasicReject < ::FFI::Struct
      layout(
        :delivery_tag, :uint64,
        :requeue, Boolean
      )
      
      def self.id
        :basic_reject
      end
      
      def id
        :basic_reject
      end
      
      def apply(delivery_tag: nil, requeue: nil)
        self[:delivery_tag] = Integer(delivery_tag) if delivery_tag
        self[:requeue] = requeue unless requeue.nil?
        self
      end
      
      def to_h(free=false)
        {
          delivery_tag: self[:delivery_tag],
          requeue: self[:requeue]
        }
      end
      
      def free!
      end
      
    end
  end
end
