
module RabbitMQ
  module FFI
    class ConnectionStart < ::FFI::Struct
      layout(
        :version_major, :uint8,
        :version_minor, :uint8,
        :server_properties, Table,
        :mechanisms, Bytes,
        :locales, Bytes
      )
      
      def self.id
        :connection_start
      end
      
      def id
        :connection_start
      end
      
      def apply(version_major: nil, version_minor: nil, server_properties: nil, mechanisms: nil, locales: nil)
        self[:version_major] = Integer(version_major) if version_major
        self[:version_minor] = Integer(version_minor) if version_minor
        self[:server_properties] = Table.from(server_properties) if server_properties
        self[:mechanisms] = Bytes.from_s(mechanisms.to_s) if mechanisms
        self[:locales] = Bytes.from_s(locales.to_s) if locales
        self
      end
      
      def to_h(free=false)
        {
          version_major: self[:version_major],
          version_minor: self[:version_minor],
          server_properties: self[:server_properties].to_h(free),
          mechanisms: self[:mechanisms].to_s(free),
          locales: self[:locales].to_s(free)
        }
      end
      
      def free!
        self[:server_properties].free!
        self[:mechanisms].free!
        self[:locales].free!
      end
      
    end
  end
end
