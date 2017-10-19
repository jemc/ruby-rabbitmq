
module RabbitMQ
  module FFI
    class BasicCancel < ::FFI::Struct
      layout(
        :consumer_tag, Bytes,
        :nowait, Boolean
      )
      
      def self.id
        :basic_cancel
      end
      
      def id
        :basic_cancel
      end
      
      def apply(consumer_tag: nil, nowait: nil)
        self[:consumer_tag] = Bytes.from_s(consumer_tag.to_s) if consumer_tag
        self[:nowait] = nowait unless nowait.nil?
        self
      end
      
      def to_h(free=false)
        {
          consumer_tag: self[:consumer_tag].to_s(free),
          nowait: self[:nowait]
        }
      end
      
      def free!
        self[:consumer_tag].free!
      end
      
    end
  end
end
