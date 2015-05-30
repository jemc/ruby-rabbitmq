
module RabbitMQ
  class Connection
    def initialize *args
      @conn = FFI.amqp_new_connection
      parse_info(*args)
      
      @finalizer = self.class.send :create_finalizer_for, @conn
      ObjectSpace.define_finalizer self, @finalizer
    end
    
    def destroy
      if @finalizer
        @finalizer.call
        ObjectSpace.undefine_finalizer self
      end
      @conn = @finalizer = nil
    end
    
    # @private
    def self.create_finalizer_for(conn)
      Proc.new { FFI.amqp_destroy_connection(conn) }
    end
    
    def user;     @info[:user];     end
    def password; @info[:password]; end
    def host;     @info[:host];     end
    def vhost;    @info[:vhost];    end
    def port;     @info[:port];     end
    def ssl?;     @info[:ssl];      end
    
    private def parse_info url=nil
      info = FFI::ConnectionInfo.new
      url_ptr = Util.strdup_ptr(url) if url
      
      if url_ptr
        Util.error_check FFI.amqp_parse_url(url_ptr, info.pointer)
      else
        FFI.amqp_default_connection_info(info.pointer)
      end
      
      # We must copy the members of ConnectionInfo before the url_ptr is freed.
      @info = info.members.map { |k| [k, info[k]] }.to_h
      url_ptr.free if url_ptr
    end
    
  end
end
