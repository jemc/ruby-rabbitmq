
module RabbitMQ
  module FFI
    class ChannelClose < ::FFI::Struct
      layout(
        :reply_code, :uint16,
        :reply_text, Bytes,
        :class_id, :uint16,
        :method_id, :uint16
      )
      
      def self.id
        :channel_close
      end
      
      def id
        :channel_close
      end
      
      def apply(reply_code: nil, reply_text: nil, method: nil)
        if method
          method_id = FFI::MethodNumber[method.to_sym]
          self[:class_id] = method_id >> 16
          self[:method_id] = method_id & 0xFFFF
        end
        self[:reply_code] = Integer(reply_code) if reply_code
        self[:reply_text] = Bytes.from_s(reply_text.to_s) if reply_text
        self
      end
      
      def to_h(free=false)
        {
          reply_code: self[:reply_code],
          reply_text: self[:reply_text].to_s(free),
          method: FFI::MethodNumber[self[:method_id] + (self[:class_id] << 16)]
        }
      end
      
      def free!
        self[:reply_text].free!
      end
      
    end
  end
end
