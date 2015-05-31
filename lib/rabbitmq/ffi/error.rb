
module RabbitMQ
  module FFI
    
    class Error < RuntimeError
      def initialize message=nil
        @message = message
      end
      
      def message
        if @message && status_message; "#{status_message} - #{@message}"
        elsif @message;                @message
        elsif status_message;          status_message
        else;                          ""
        end
      end
      
      def status_message
        nil
      end
      
      @lookup_table = {}
      class << self
        attr_reader :lookup_table
      end
      
      def self.lookup status
        lookup_table.fetch(status)
      end
      
      FFI::Status.symbols.each do |status|
        message    = RabbitMQ::FFI.amqp_error_string2(status)
        const_name = status.to_s.gsub(/((?:\A\w)|(?:_\w))/) { |x| x[-1].upcase }
        
        kls = Class.new(Error) { define_method(:status_message) { message } }
        lookup_table[status] = kls
        const_set const_name, kls
      end
    end
    
  end
end
