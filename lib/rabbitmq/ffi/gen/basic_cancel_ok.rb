
module RabbitMQ
  module FFI
    class BasicCancelOk < ::FFI::Struct
      layout(:consumer_tag, Bytes)
      
      def self.id
        :basic_cancel_ok
      end
      
      def id
        :basic_cancel_ok
      end
      
      def apply(consumer_tag: nil)
        self[:consumer_tag] = Bytes.from_s(consumer_tag.to_s) if consumer_tag
        self
      end
      
      def to_h(free=false)
        {consumer_tag: self[:consumer_tag].to_s(free)}
      end
      
      def free!
        self[:consumer_tag].free!
      end
      
    end
  end
end
