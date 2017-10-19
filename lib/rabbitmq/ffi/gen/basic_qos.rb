
module RabbitMQ
  module FFI
    class BasicQos < ::FFI::Struct
      layout(
        :prefetch_size, :uint32,
        :prefetch_count, :uint16,
        :global, Boolean
      )
      
      def self.id
        :basic_qos
      end
      
      def id
        :basic_qos
      end
      
      def apply(prefetch_size: nil, prefetch_count: nil, global: nil)
        self[:prefetch_size] = Integer(prefetch_size) if prefetch_size
        self[:prefetch_count] = Integer(prefetch_count) if prefetch_count
        self[:global] = global unless global.nil?
        self
      end
      
      def to_h(free=false)
        {
          prefetch_size: self[:prefetch_size],
          prefetch_count: self[:prefetch_count],
          global: self[:global]
        }
      end
      
      def free!
      end
      
    end
  end
end
