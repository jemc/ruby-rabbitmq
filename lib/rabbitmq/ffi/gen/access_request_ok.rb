
module RabbitMQ
  module FFI
    class AccessRequestOk < ::FFI::Struct
      layout(:ticket, :uint16)
      
      def self.id
        :access_request_ok
      end
      
      def id
        :access_request_ok
      end
      
      def apply(ticket: nil)
        self[:ticket] = Integer(ticket) if ticket
        self
      end
      
      def to_h(free=false)
        {ticket: self[:ticket]}
      end
      
      def free!
      end
      
    end
  end
end
