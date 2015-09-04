
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
        when :timestamp; Time.at(value).utc
        when :table;     value.to_h(free)
        when :array;     value.to_a(free)
        else value
        end
        
        clear if free
        result
      end
      
      def free!
        kind  = self[:kind]
        value = self[:value][value_member(kind)]
        value.free! if value.respond_to? :free!
        self
      end
      
      def apply(value)
        self[:kind], self[:value] = case value
        when ::String; [:bytes, FieldValueValue.new(Bytes.from_s(value).pointer)]
        when ::Symbol; [:bytes, FieldValueValue.new(Bytes.from_s(value.to_s).pointer)]
        when ::Array;  [:array, FieldValueValue.new(Array.from_a(value).pointer)]
        when ::Hash;   [:table, FieldValueValue.new(Table.from(value).pointer)]
        when ::Fixnum; [:i64,       (v=FieldValueValue.new; v[:i64]=value; v)]
        when ::Float;  [:f64,       (v=FieldValueValue.new; v[:f64]=value; v)]
        when ::Time;   [:timestamp, (v=FieldValueValue.new; v[:u64]=value.to_i; v)]
        when true;     [:boolean,   (v=FieldValueValue.new; v[:boolean]=true; v)]
        when false;    [:boolean,   (v=FieldValueValue.new; v[:boolean]=false; v)]
        else raise NotImplementedError, "#{self.class}.from(#<#{value.class}>)"
        end
        self
      end
      
      def self.from(value)
        new.apply(value)
      end
    end
    
  end
end
