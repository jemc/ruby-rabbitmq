
module RabbitMQ
  module FFI
    
    class BasicProperties
      def apply(**params)
        params.each do |key, value|
          next if value.nil?
          case value
          when String; value = FFI::Bytes.from_s(value)
          when Hash;   value = FFI::Table.from(value)
          end
          set_flag_for_key(key)
          self[key] = value
        end
        self
      end
      
      def to_h(free=false)
        result = {}
        self.members.each do |key| [key, self[key]]
          next unless flag_for_key?(key)
          value = self[key]
          case value
          when FFI::Bytes; value = value.to_s(free)
          when FFI::Table; value = value.to_h(free)
          end
          result[key] = value
        end
        
        clear if free
        result
      end
      
      def free!
        self.values.each do |item|
          item.free! if item.respond_to? :free!
        end
        clear
      end
      
      def set_flag_for_key(key)
        flag_bit = FLAGS[key]
        return unless flag_bit
        self[:_flags] = (self[:_flags] | flag_bit)
      end
      
      def flag_for_key?(key)
        return false if key == :_flags
        flag_bit = FLAGS[key]
        return true unless flag_bit
        return (flag_bit & self[:_flags]) != 0
      end
    end
    
  end
end
