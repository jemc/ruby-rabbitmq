
require 'socket'

module RabbitMQ
  class Connection
    def initialize *args
      @ptr  = FFI.amqp_new_connection
      @info = Util.connection_info(*args)
      
      @open_channels     = {}
      @released_channels = {}
      @incoming_events   = Hash.new { |h,k| h[k] = {} }
      
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
    
    private def ptr
      raise DestroyedError unless @ptr
      @ptr
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
      
      @ruby_socket = Socket.for_fd(FFI.amqp_get_sockfd(@ptr))
    end
    
    private def login!
      raise DestroyedError unless @ptr
      
      res = FFI.amqp_login(@ptr, vhost, max_channels, max_frame_size,
        heartbeat_interval, :plain, :string, user, :string, password)
      
      case res[:reply_type]
      when :library_exception; Util.error_check :"logging in", res[:library_error]
      when :server_exception;  raise NotImplementedError
      end
      
      @server_properties = FFI::Table.new(FFI.amqp_get_server_properties(@ptr)).to_h
    end
    
    private def open_channel(id)
      Util.error_check :"opening a new channel",
        send_method(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
    end
    
    private def reopen_channel(id)
      Util.error_check :"acknowledging server-initated channel closure",
        send_method(id, :channel_close_ok)
      
      Util.error_check :"reopening channel after server-initated closure",
        send_method(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
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
    
    private def send_method(channel, type, properties={})
      raise DestroyedError unless @ptr
      
      req    = FFI::Method.lookup_class(type).new.apply(properties)
      status = FFI.amqp_send_method(@ptr, channel, type, req.pointer)
      req.free!
      status
    end
    
    private def select(timeout=0, start=Time.now)
      if timeout
        timeout = timeout - (start-Time.now)
        timeout = 0 if timeout < 0
      end
      
      IO.select([@ruby_socket], [], [], timeout) ? true : false
    end
    
    private def fetch_next_frame(timeout=0, start=Time.now)
      frame  = FFI::Frame.new
      
      # Try fetching the next frame without a blocking call.
      status = FFI.amqp_simple_wait_frame_noblock(@ptr, frame, FFI::Timeval.zero)
      case status
      when :ok;      return frame
      when :timeout; # do nothing and proceed to waiting on select below
      else Util.error_check :"fetching the next frame", status
      end
      
      # Otherwise, wait for the socket to be readable and try fetching again.
      return nil unless select(timeout, start)
      Util.error_check :"fetching the next frame",
        FFI.amqp_simple_wait_frame(@ptr, frame)
      
      frame
    end
    
    private def fetch_next_event(timeout=0, start=Time.now)
      frame = fetch_next_frame(timeout, start)
      return unless frame
      event = frame.as_method_to_h(false)
      return event unless FFI::Method.has_content?(event.fetch(:method))
      
      frame = fetch_next_frame(timeout, start)
      return unless frame
      event.merge!(frame.as_header_to_h)
      
      body = ""
      while body.size < event.fetch(:body_size)
        frame = fetch_next_frame(timeout, start)
        return unless frame
        body.concat frame.as_body_to_s
      end
      
      event[:body] = body
      event
    end
    
    private def handle_incoming_event(event)
      method = event.fetch(:method)
      
      case method
      when :channel_close
        raise_if_server_error!(event)
      when :connection_close
        raise_if_server_error!(event)
      else
        @incoming_events[event.fetch(:channel)][method] = event
      end
    end
    
    private def fetch_events(timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      FFI.amqp_maybe_release_buffers(@ptr)
      
      while (event = fetch_next_event(timeout, start))
        handle_incoming_event(event)
      end
    end
    
    private def raise_if_server_error!(event)
      if (exc = ServerError.from(event))
        if exc.is_a?(ServerError::Channel)
          reopen_channel(event.fetch(:channel))
        elsif exc.is_a?(ServerError::Connection)
          raise NotImplementedError
        end
        raise exc
      end
    end
    
    private def fetch_response(channel, method, timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      found = @incoming_events[channel].delete(method)
      return found if found
      
      FFI.amqp_maybe_release_buffers_on_channel(@ptr, channel)
      
      while (event = fetch_next_event(timeout, start))
        return event if event.fetch(:channel) == channel \
                     && event.fetch(:method)  == method
        handle_incoming_event(event)
      end
      
      raise FFI::Error::Timeout, "waiting for response"
    end
  end
end
