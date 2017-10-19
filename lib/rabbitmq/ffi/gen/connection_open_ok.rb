
module RabbitMQ
  module FFI
    class ConnectionOpenOk < ::FFI::Struct
      layout(:known_hosts, Bytes)
      
      def self.id
        :connection_open_ok
      end
      
      def id
        :connection_open_ok
      end
      
      def apply(known_hosts: nil)
        self[:known_hosts] = Bytes.from_s(known_hosts.to_s) if known_hosts
        self
      end
      
      def to_h(free=false)
        {known_hosts: self[:known_hosts].to_s(free)}
      end
      
      def free!
        self[:known_hosts].free!
      end
      
    end
  end
end
