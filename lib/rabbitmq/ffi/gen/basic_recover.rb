
module RabbitMQ
  module FFI
    class BasicRecover < ::FFI::Struct
      layout(:requeue, Boolean)
      
      def self.id
        :basic_recover
      end
      
      def id
        :basic_recover
      end
      
      def apply(requeue: nil)
        self[:requeue] = requeue unless requeue.nil?
        self
      end
      
      def to_h(free=false)
        {requeue: self[:requeue]}
      end
      
      def free!
      end
      
    end
  end
end
