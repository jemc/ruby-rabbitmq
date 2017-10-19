
module RabbitMQ
  module FFI
    class ConfirmSelect < ::FFI::Struct
      layout(:nowait, Boolean)
      
      def self.id
        :confirm_select
      end
      
      def id
        :confirm_select
      end
      
      def apply(nowait: nil)
        self[:nowait] = nowait unless nowait.nil?
        self
      end
      
      def to_h(free=false)
        {nowait: self[:nowait]}
      end
      
      def free!
      end
      
    end
  end
end
