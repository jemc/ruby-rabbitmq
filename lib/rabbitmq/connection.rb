
module RabbitMQ
  class Connection
    def initialize url=nil
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
    
    def user;     @info[:user];     end
    def password; @info[:password]; end
    def host;     @info[:host];     end
    def vhost;    @info[:vhost];    end
    def port;     @info[:port];     end
    def ssl?;     @info[:ssl];      end
    
  end
end
