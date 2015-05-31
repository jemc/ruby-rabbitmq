
module RabbitMQ
  module FFI
    
    class ConnectionInfo
      def to_h
        members.map { |k| [k, self[k]] }.to_h
      end
    end
    
  end
end
