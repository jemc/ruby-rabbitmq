
module RabbitMQ
  module FFI
    class ConnectionBlocked < ::FFI::Struct
      layout(:reason, Bytes)
      
      def self.id
        :connection_blocked
      end
      
      def id
        :connection_blocked
      end
      
      def apply(reason: nil)
        self[:reason] = Bytes.from_s(reason.to_s) if reason
        self
      end
      
      def to_h(free=false)
        {reason: self[:reason].to_s(free)}
      end
      
      def free!
        self[:reason].free!
      end
      
    end
  end
end
