
module RabbitMQ
  module FFI
    class AccessRequest < ::FFI::Struct
      layout(
        :realm, Bytes,
        :exclusive, Boolean,
        :passive, Boolean,
        :active, Boolean,
        :write, Boolean,
        :read, Boolean
      )
      
      def self.id
        :access_request
      end
      
      def id
        :access_request
      end
      
      def apply(realm: nil, exclusive: nil, passive: nil, active: nil, write: nil, read: nil)
        self[:realm] = Bytes.from_s(realm.to_s) if realm
        self[:exclusive] = exclusive unless exclusive.nil?
        self[:passive] = passive unless passive.nil?
        self[:active] = active unless active.nil?
        self[:write] = write unless write.nil?
        self[:read] = read unless read.nil?
        self
      end
      
      def to_h(free=false)
        {
          realm: self[:realm].to_s(free),
          exclusive: self[:exclusive],
          passive: self[:passive],
          active: self[:active],
          write: self[:write],
          read: self[:read]
        }
      end
      
      def free!
        self[:realm].free!
      end
      
    end
  end
end
