
module RabbitMQ
  module FFI
    
    class Method
      MethodClasses = FFI::MethodNumber.symbols.map do |name|
        const_name = name.to_s.gsub(/((?:\A\w)|(?:_\w))/) { |x| x[-1].upcase }
        [name, FFI.const_get(const_name)]
      end.to_h.freeze
      
      MethodNames = MethodClasses.to_a.map(&:reverse).to_h.freeze
      
      def to_h(free=false)
        { method: self[:id],
          properties: self.decoded.to_h(free) }
      end
      
      def decoded
        MethodClasses.fetch(self[:id]).new(self[:decoded])
      end
      
      def self.lookup(kls)
        MethodNames.fetch(kls)
      end
      
      def self.lookup_class(name)
        MethodClasses.fetch(name)
      end
      
      def self.from(decoded)
        obj = new
        obj[:id] = lookup(decoded.class)
        obj[:decoded] = decoded.pointer
        obj
      end
      
      def self.has_content?(type)
        case type
        when :basic_publish; true
        when :basic_return;  true
        when :basic_deliver; true
        when :basic_get_ok;  true
        else                 false
        end
      end
    end
    
  end
end
