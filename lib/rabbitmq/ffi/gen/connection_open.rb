
module RabbitMQ
  module FFI
    class ConnectionOpen < ::FFI::Struct
      layout(
        :virtual_host, Bytes,
        :capabilities, Bytes,
        :insist, Boolean
      )
      
      def self.id
        :connection_open
      end
      
      def id
        :connection_open
      end
      
      def apply(virtual_host: nil, capabilities: nil, insist: nil)
        self[:virtual_host] = Bytes.from_s(virtual_host.to_s) if virtual_host
        self[:capabilities] = Bytes.from_s(capabilities.to_s) if capabilities
        self[:insist] = insist unless insist.nil?
        self
      end
      
      def to_h(free=false)
        {
          virtual_host: self[:virtual_host].to_s(free),
          capabilities: self[:capabilities].to_s(free),
          insist: self[:insist]
        }
      end
      
      def free!
        self[:virtual_host].free!
        self[:capabilities].free!
      end
      
    end
  end
end
