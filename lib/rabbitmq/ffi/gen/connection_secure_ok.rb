
module RabbitMQ
  module FFI
    class ConnectionSecureOk < ::FFI::Struct
      layout(:response, Bytes)
      
      def self.id
        :connection_secure_ok
      end
      
      def id
        :connection_secure_ok
      end
      
      def apply(response: nil)
        self[:response] = Bytes.from_s(response.to_s) if response
        self
      end
      
      def to_h(free=false)
        {response: self[:response].to_s(free)}
      end
      
      def free!
        self[:response].free!
      end
      
    end
  end
end
