
module RabbitMQ
  module FFI
    
    class Table
      include Enumerable
      
      def each(*a, &b)
        entry_ptr = self[:entries]
        entries   = self[:num_entries].times.map do |i|
          FFI::TableEntry.new(entry_ptr + i * FFI::TableEntry.size)
        end
        entries.each(*a, &b)
      end
      
      def to_h(free=false)
        result = self.map do |entry|
          [entry[:key].to_s(free), entry[:value].to_value(free)]
        end.to_h
        
        clear if free
        result
      end
      
      def free!
        self.each do |entry|
          entry[:key].free!
          entry[:value].free!
        end
        FFI.free(self[:entries])
        clear
      end
      
      def self.from(params)
        size      = params.size
        entry_ptr = Util.mem_ptr(size * FFI::TableEntry.size, release: false)
        params.each_with_index do |param, idx|
          entry = FFI::TableEntry.new(entry_ptr + idx * FFI::TableEntry.size)
          entry[:key]   = FFI::Bytes.from_s(param.first.to_s)
          entry[:value] = FFI::FieldValue.from(param.last)
        end
        
        obj = new
        obj[:num_entries] = size
        obj[:entries]     = entry_ptr
        obj
      end
    end
    
  end
end
