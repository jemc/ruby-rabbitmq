
module RabbitMQ
  module FFI
    
    class Timeval
      def self.from(seconds)
        obj = new
        obj[:tv_sec] = Integer(seconds)
        obj[:tv_usec] = Integer(Float(seconds) * 1_000_000)
        obj
      end
      
      @zero = self.from(0)
      class << self; attr_reader :zero; end
    end
    
  end
end
