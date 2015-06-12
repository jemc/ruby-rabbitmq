
require_relative 'client/connection'

module RabbitMQ
  class Client
    def initialize *args
      @info = Util.connection_info(*args)
      @conn = Connection.new(self)
      
      @open_channels     = {}
      @released_channels = {}
      @event_handlers    = Hash.new { |h,k| h[k] = {} }
      @incoming_events   = Hash.new { |h,k| h[k] = {} }
    end
    
    def destroy
      @conn.destroy
    end
    
    def user;     @info.fetch(:user);     end
    def password; @info.fetch(:password); end
    def host;     @info.fetch(:host);     end
    def vhost;    @info.fetch(:vhost);    end
    def port;     @info.fetch(:port);     end
    def ssl?;     @info.fetch(:ssl);      end
    
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
      @conn.connect_socket!
      @conn.login!
      
      self
    end
    
    def close
      @conn.close
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
        @conn.send_method(Integer(channel_id), method.to_sym, properties)
      
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
      Channel.new(self, allocate_channel(id))
    end
    
    private def ptr
      @conn.ptr
    end
    
    private def open_channel(id)
      Util.error_check :"opening a new channel",
        @conn.send_method(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
    end
    
    private def reopen_channel(id)
      Util.error_check :"acknowledging server-initated channel closure",
        @conn.send_method(id, :channel_close_ok)
      
      Util.error_check :"reopening channel after server-initated closure",
        @conn.send_method(id, :channel_open)
      
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
      @conn.garbage_collect
      
      while (event = @conn.fetch_next_event(timeout, start))
        handle_incoming_event(event)
        store_incoming_event(event)
        break if @breaking
      end
    end
    
    private def fetch_response_internal(channel_id, methods, timeout=protocol_timeout, start=Time.now)
      methods.each { |method|
        found = @incoming_events[channel_id].delete(method)
        return found if found
      }
      
      @conn.garbage_collect_channel(channel_id)
      
      while (event = @conn.fetch_next_event(timeout, start))
        handle_incoming_event(event)
        return event if channel_id == event.fetch(:channel) \
                     && methods.include?(event.fetch(:method))
        store_incoming_event(event)
      end
      
      raise FFI::Error::Timeout, "waiting for response"
    end
  end
end
