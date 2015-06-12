
module RabbitMQ
  module FFI
    
    class FieldValue
      private def value_member(kind)
        case kind
        when :utf8;      :bytes
        when :timestamp; :u64
        else kind
        end
      end
      
      def to_value(free=false)
        kind   = self[:kind]
        value  = self[:value][value_member(kind)]
        result = case kind
        when :bytes;     value.to_s(free)
        when :utf8;      value.to_s(free).force_encoding(Encoding::UTF_8)
        when :timestamp; Time.at(value / 1000.0)
        when :table;     value.to_h(free)
        when :array;     value.to_array_not_yet_implemented!
        when :decimal;   value.to_value_not_yet_implemented!
        else value
        end
        
        clear if free
        result
      end
      
      def free!
        kind   = self[:kind]
        value  = self[:value][value_member(kind)]
        value.free! if value.respond_to? :free!
        clear
      end
      
      def self.from(value)
        obj = new
        obj[:kind], obj[:value] = case value
        when String; [:bytes, FieldValueValue.new(Bytes.from_s(value).pointer)]
        else raise NotImplementedError
        end
        obj
      end
    end
    
  end
end
