
module RabbitMQ
  module FFI
    class ConnectionStartOk < ::FFI::Struct
      layout(
        :client_properties, Table,
        :mechanism, Bytes,
        :response, Bytes,
        :locale, Bytes
      )
      
      def self.id
        :connection_start_ok
      end
      
      def id
        :connection_start_ok
      end
      
      def apply(client_properties: nil, mechanism: nil, response: nil, locale: nil)
        self[:client_properties] = Table.from(client_properties) if client_properties
        self[:mechanism] = Bytes.from_s(mechanism.to_s) if mechanism
        self[:response] = Bytes.from_s(response.to_s) if response
        self[:locale] = Bytes.from_s(locale.to_s) if locale
        self
      end
      
      def to_h(free=false)
        {
          client_properties: self[:client_properties].to_h(free),
          mechanism: self[:mechanism].to_s(free),
          response: self[:response].to_s(free),
          locale: self[:locale].to_s(free)
        }
      end
      
      def free!
        self[:client_properties].free!
        self[:mechanism].free!
        self[:response].free!
        self[:locale].free!
      end
      
    end
  end
end
