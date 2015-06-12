
module RabbitMQ
  module FFI
    
    class ConnectionInfo
      def to_h
        members.zip(values).to_h
      end
    end
    
  end
end
