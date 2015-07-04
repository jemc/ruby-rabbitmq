
module RabbitMQ
  module FFI
    
    class Array
      include Enumerable
      
      def each(*a, &b)
        entry_ptr = self[:entries]
        entries   = self[:num_entries].times.map do |i|
          FFI::FieldValue.new(entry_ptr + i * FFI::FieldValue.size)
        end
        entries.each(*a, &b)
      end
      
      def to_a(free=false)
        result = self.map do |item|
          item.to_value(free)
        end
        
        clear if free
        result
      end
      
      def free!
        self.each(&:free!)
        FFI.free(self[:entries])
        clear
      end
      
      def self.from_a(items)
        size      = items.size
        entry_ptr = Util.mem_ptr(size * FFI::FieldValue.size, release: false)
        items.each_with_index do |item, idx|
          FFI::FieldValue.new(entry_ptr + idx * FFI::FieldValue.size).apply(item)
        end
        
        obj = new
        obj[:num_entries] = size
        obj[:entries]     = entry_ptr
        obj
      end
    end
    
  end
end
