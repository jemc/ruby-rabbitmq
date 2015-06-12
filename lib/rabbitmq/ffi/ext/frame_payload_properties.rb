
module RabbitMQ
  module FFI
    
    class FramePayloadProperties
      def decoded
        BasicProperties.new(self[:decoded])
      end
    end
    
  end
end
