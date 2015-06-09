
require 'socket'

module RabbitMQ
  class Connection
    def initialize *args
      @ptr  = FFI.amqp_new_connection
      @info = Util.connection_info(*args)
      
      @open_channels     = {}
      @released_channels = {}
      @event_handlers    = Hash.new { |h,k| h[k] = {} }
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
    
    # Send a request on the given channel with the given type and properties.
    #
    # @param channel_id [Integer] The channel number to send on.
    # @param method [Symbol] The type of protocol method to send.
    # @param properties [Hash] The properties to apply to the method.
    # @raise [RabbitMQ::FFI::Error] if a library exception occurs.
    #
    def send_request(channel_id, method, properties={})
      Util.error_check :"sending a request",
        send_request_internal(Integer(channel_id), method.to_sym, properties)
      
      nil
    end
    
    # Wait for a specific response on the given channel of the given type
    # and return the event data for the response when it is received.
    # Any other events received will be processed or stored internally.
    #
    # @param channel_id [Integer] The channel number to watch for.
    # @param method [Symbol,Array<Symbol>] The protocol method(s) to watch for.
    # @param timeout [Float] The maximum time to wait for a response in seconds;
    #   uses the value of {#protocol_timeout} by default.
    # @raise [RabbitMQ::ServerError] if any error event is received.
    # @raise [RabbitMQ::FFI::Error::Timeout] if no event is received.
    # @raise [RabbitMQ::FFI::Error] if a library exception occurs.
    # @return [Hash] the response data received.
    #
    def fetch_response(channel_id, method, timeout=protocol_timeout)
      methods = Array(method).map(&:to_sym)
      fetch_response_internal(Integer(channel_id), methods, Float(timeout))
    end
    
    # Register a handler for events on the given channel of the given type.
    #
    # @param channel_id [Integer] The channel number to watch for.
    # @param method [Symbol] The type of protocol method to watch for.
    # @param callable [#call,nil] The callable handler if no block is given.
    # @param block [Proc,nil] The handler block to register.
    # @return [Proc,#call] The given block or callable.
    # @yieldparam event [Hash] The event passed to the handler.
    #
    def on_event(channel_id, method, callable=nil, &block)
      handler = block || callable
      raise ArgumentError, "expected block or callable as event handler" \
        unless handler.respond_to?(:call)
      
      @event_handlers[Integer(channel_id)][method.to_sym] = handler
      handler
    end
    
    # Fetch and handle events in a loop that blocks the calling thread.
    # The loop will continue until the {#break!} method is called from within
    # an event handler, or until the given timeout duration has elapsed.
    #
    # @param timeout [Float] the maximum time to run the loop, in seconds;
    #   if none is given, the loop will block indefinitely or until {#break!}.
    #
    def run_loop!(timeout=nil)
      timeout = Float(timeout) if timeout
      @breaking = false
      fetch_events(timeout)
      nil
    end
    
    # Stop iterating from within an execution of the {#run_loop!} method.
    # Call this method only from within an event handler.
    # It will take effect only after the handler finishes running.
    #
    # @return [nil]
    #
    def break!
      @breaking = true
      nil
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
        send_request_internal(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
    end
    
    private def reopen_channel(id)
      Util.error_check :"acknowledging server-initated channel closure",
        send_request_internal(id, :channel_close_ok)
      
      Util.error_check :"reopening channel after server-initated closure",
        send_request_internal(id, :channel_open)
      
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
      @event_handlers[id] ||= {}
      
      id
    end
    
    private def release_channel(id)
      @open_channels.delete(id)
      @event_handlers.delete(id)
      @released_channels[id] = true
    end
    
    private def release_all_channels
      @open_channels.clear
      @event_handlers.clear
      @released_channels.clear
    end
    
    # Block until there is readable data on the internal ruby socket,
    # returning true if there is readable data, or false if time expired.
    private def select(timeout=0, start=Time.now)
      if timeout
        timeout = timeout - (start-Time.now)
        timeout = 0 if timeout < 0
      end
      
      IO.select([@ruby_socket], [], [], timeout) ? true : false
    end
    
    # Return the next available frame, or nil if time expired.
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
    
    # Fetch the next one or more frames to form the next discrete event,
    # returning the event as a Hash, or nil if time expired.
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
    
    # Execute the handler for this type of event, if any
    private def handle_incoming_event(event)
      if (handlers = @event_handlers[event.fetch(:channel)])
        if (handler = (handlers[event.fetch(:method)]))
          handler.call(event)
        end
      end
    end
    
    # Store the event in short-term storage for retrieval by fetch_response.
    # If another event is received with the same method name, it will
    # overwrite this one - fetch_response gets the latest or next by method.
    # Raises an exception if the incoming event is an error condition.
    private def store_incoming_event(event)
      method  = event.fetch(:method)
      
      case method
      when :channel_close
        raise_if_server_error!(event)
      when :connection_close
        raise_if_server_error!(event)
      else
        @incoming_events[event.fetch(:channel)][method] = event
      end
    end
    
    # Raise an exception if the incoming event is an error condition.
    # Also takes action to reopen the channel or close the connection.
    private def raise_if_server_error!(event)
      if (exc = ServerError.from(event))
        if exc.is_a?(ServerError::ChannelError)
          reopen_channel(event.fetch(:channel)) # recover by reopening the channel
        elsif exc.is_a?(ServerError::ConnectionError)
          close # can't recover here - close and let the user recover manually
        end
        raise exc
      end
    end
    
    private def fetch_events(timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      FFI.amqp_maybe_release_buffers(@ptr)
      
      while (event = fetch_next_event(timeout, start))
        handle_incoming_event(event)
        store_incoming_event(event)
        break if @breaking
      end
    end
    
    private def fetch_response_internal(channel, methods, timeout=protocol_timeout, start=Time.now)
      raise DestroyedError unless @ptr
      
      methods.each do |method|
        found = @incoming_events[channel].delete(method)
        return found if found
      end
      
      FFI.amqp_maybe_release_buffers_on_channel(@ptr, channel)
      
      while (event = fetch_next_event(timeout, start))
        handle_incoming_event(event)
        return event if channel == event.fetch(:channel) \
                     && methods.include?(event.fetch(:method))
        store_incoming_event(event)
      end
      
      raise FFI::Error::Timeout, "waiting for response"
    end
    
    private def send_request_internal(channel_id, method, properties={})
      raise DestroyedError unless @ptr
      
      req    = FFI::Method.lookup_class(method).new.apply(properties)
      status = FFI.amqp_send_method(@ptr, channel_id, method, req.pointer)
      
      req.free!
      status
    end
  end
end
