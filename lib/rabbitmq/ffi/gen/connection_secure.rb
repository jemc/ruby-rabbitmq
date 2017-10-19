
module RabbitMQ
  module FFI
    class ConnectionSecure < ::FFI::Struct
      layout(:challenge, Bytes)
      
      def self.id
        :connection_secure
      end
      
      def id
        :connection_secure
      end
      
      def apply(challenge: nil)
        self[:challenge] = Bytes.from_s(challenge.to_s) if challenge
        self
      end
      
      def to_h(free=false)
        {challenge: self[:challenge].to_s(free)}
      end
      
      def free!
        self[:challenge].free!
      end
      
    end
  end
end
