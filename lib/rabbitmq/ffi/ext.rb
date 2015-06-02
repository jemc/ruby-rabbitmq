
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
        bytes[:len]   = str.bytesize
        bytes[:bytes] = Util.mem_ptr(str.bytesize, release: false)
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
    
  end
end
