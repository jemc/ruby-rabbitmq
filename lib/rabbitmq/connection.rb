
module RabbitMQ
  class Connection
    def initialize *args
      @ptr  = FFI.amqp_new_connection
      @info = Util.connection_info(*args)
      
      @open_channels     = {}
      @released_channels = {}
      @incoming_events   = Hash.new { |h,k| h[k] = [] }
      
      create_socket!
      
      @finalizer = self.class.send :create_finalizer_for, @ptr
      ObjectSpace.define_finalizer self, @finalizer
    end
    
    def destroy
      if @finalizer
        @finalizer.call
        ObjectSpace.undefine_finalizer self
      end
      @ptr = @socket = @finalizer = nil
    end
    
    class DestroyedError < RuntimeError; end
    
    # @private
    def self.create_finalizer_for(ptr)
      Proc.new do
        FFI.amqp_connection_close(ptr, 200)
        FFI.amqp_destroy_connection(ptr)
      end
    end
    
    def user;     @info[:user];     end
    def password; @info[:password]; end
    def host;     @info[:host];     end
    def vhost;    @info[:vhost];    end
    def port;     @info[:port];     end
    def ssl?;     @info[:ssl];      end
    
    def protocol_timeout
      @protocol_timeout ||= 30 # seconds
    end
    attr_writer :protocol_timeout
    
    def max_channels
      @max_channels ||= FFI::CHANNEL_MAX_ID
    end
    attr_writer :max_channels
    
    def max_frame_size
      @max_frame_size ||= 131072
    end
    attr_writer :max_frame_size
    
    def heartbeat_interval; 0; end # not fully implemented in librabbitmq
    
    def start
      close # Close if already open
      connect_socket!
      login!
      
      self
    end
    
    def close
      raise DestroyedError unless @ptr
      FFI.amqp_connection_close(@ptr, 200)
      
      release_all_channels
      
      self
    end
    
    def channel(id=nil)
      Channel.new(self, allocate_channel(id), pre_allocated: true)
    end
    
    private def create_socket!
      raise DestroyedError unless @ptr
      
      @socket = FFI.amqp_tcp_socket_new(@ptr)
      Util.null_check :"creating a socket", @socket
    end
    
    private def connect_socket!
      raise DestroyedError unless @ptr
      raise NotImplementedError if ssl?
      
      create_socket!
      Util.error_check :"opening a socket",
        FFI.amqp_socket_open(@socket, host, port)
    end
    
    private def login!
      raise DestroyedError unless @ptr
      
      rpc_check :"logging in",
        FFI.amqp_login(@ptr, vhost, max_channels, max_frame_size,
          heartbeat_interval, :plain, :string, user, :string, password)
      
      @server_properties = FFI::Table.new(FFI.amqp_get_server_properties(@ptr)).to_h
    end
    
    private def open_channel(id)
      raise DestroyedError unless @ptr
      
      FFI.amqp_channel_open(@ptr, id)
      rpc_check :"opening channel", FFI.amqp_get_rpc_reply(@ptr)
    end
    
    private def allocate_channel(id=nil)
      if id
        raise ArgumentError, "channel #{id} is already in use" if @open_channels[id]
      elsif @released_channels.empty?
        id = (@open_channels.keys.sort.last || 0) + 1
      else
        id = @released_channels.keys.first
      end
      raise ArgumentError, "channel #{id} is too high" if id > max_channels
      
      already_open = @released_channels.delete(id)
      open_channel(id) unless already_open
      
      @open_channels[id] = true
      
      id
    end
    
    private def release_channel(id)
      @open_channels.delete(id)
      @released_channels[id] = true
    end
    
    private def release_all_channels
      @open_channels.clear
      @released_channels.clear
    end
    
    private def send_method(channel, method)
      raise DestroyedError unless @ptr
      
      method_type = FFI::Method.lookup(method.class)
      FFI.amqp_send_method(@ptr, channel, method_type, method.pointer)
    end
    
    private def fetch_next_frame(timeout=0, start=Time.now)
      frame   = FFI::Frame.new
      timeval = FFI::Timeval.from(timeout - (start-Time.now))
      status  = FFI.amqp_simple_wait_frame_noblock(@ptr, frame, timeval)
      
      case status
      when :ok;      frame
      when :timeout; nil
      else Util.error_check :"fetching the next frame", status
      end
    end
    
    private def fetch_events(timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      while (frame = fetch_next_frame!(timeout, start))
        ch_id = frame[:channel]
        event = frame.payload.decoded
        @incoming_events[ch_id] << event
      end
    end
    
    private def fetch_event_for_channel(channel, timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      found = @incoming_events[channel].pop
      return found if found
      
      while (frame = fetch_next_frame(timeout, start))
        event = frame.payload.decoded
        return event if frame[:channel] == channel
        @incoming_events[frame[:channel]] << frame.payload.decoded if frame
      end
    end
    
    private def rpc_check action, res
      case res[:reply_type]
      when :library_exception; Util.error_check action, res[:library_error]
      when :server_exception;  raise NotImplementedError
      else res
      end
    end
  end
end
