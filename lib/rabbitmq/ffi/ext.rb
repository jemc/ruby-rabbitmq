
module RabbitMQ
  module FFI
    
    class Timeval
      def self.from(seconds)
        obj = new
        obj[:tv_sec] = seconds.to_i
        obj[:tv_usec] = (seconds * 1_000_000).to_i
        obj
      end
    end
    
    class ConnectionInfo
      def to_h
        members.map { |k| [k, self[k]] }.to_h
      end
    end
    
    class Bytes
      def to_s
        ::FFI::Pointer.new(self[:bytes]).read_bytes(self[:len])
      end
      
      def self.from_s(str)
        size = str.bytesize
        ptr  = Util.mem_ptr(size, release: false)
        ptr.write_string(str)
        
        bytes = new
        bytes[:len]   = size
        bytes[:bytes] = ptr
        bytes
      end
    end
    
    class FieldValue
      private def value_member(kind)
        case kind
        when :utf8;      :bytes
        when :timestamp; :u64
        else kind
        end
      end
      
      def to_value
        kind  = self[:kind]
        value = self[:value][value_member(kind)]
        case kind
        when :bytes;     value.to_s
        when :utf8;      value.to_s.force_encoding(Encoding::UTF_8)
        when :timestamp; Time.at(value / 1000.0)
        when :table;     value.to_h
        when :array;     value.to_array_not_yet_implemented!
        when :decimal;   value.to_value_not_yet_implemented!
        else value
        end
      end
    end
    
    class Table
      def to_h
        entry_ptr = self[:entries]
        entries   = self[:num_entries].times.map { |i|
          entry = FFI::TableEntry.new(entry_ptr + i * FFI::TableEntry.size)
          [entry[:key].to_s, entry[:value].to_value]
        }.to_h
      end
    end
    
    class Frame
      def payload
        member = case self[:frame_type]
        when :method; :method
        when :header; :properties
        when :body;   :body_fragment
        else; raise NotImplementedError, "frame type: #{self[:frame_type]}"
        end
        self[:payload][member]
      end
    end
    
    class Method
      MethodClasses = FFI::MethodNumber.symbols.map do |name|
        const_name = name.to_s.gsub(/((?:\A\w)|(?:_\w))/) { |x| x[-1].upcase }
        [name, FFI.const_get(const_name)]
      end.to_h.freeze
      
      MethodNames = MethodClasses.to_a.map(&:reverse).to_h.freeze
      
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
    end
    
    module MethodClassMixin
      def apply(params={})
        params.each do |key, value|
          case value
          when String; value = FFI::Bytes.from_s(value)
          end
          self[key] = value
        end
      end
      
      def to_h
        result = {}
        self.members.each do |key| [key, self[key]]
          value = self[key]
          case value
          when FFI::Bytes
            value = value.to_s
          end
          result[key] = value
        end
        result
      end
      
      def describe
        str = "#{self.class.to_s} {\n"
        to_h.each do |key, value|
          str.concat "  #{key}: #{value}\n"
        end
        str.concat "}"
      end
    end
    Method::MethodClasses.each { |_, kls| kls.send(:include, MethodClassMixin) }
    
  end
end
