
require_relative 'client/connection'

module RabbitMQ
  
  # A {Client} holds a connection to a RabbitMQ server and has facilities
  # for sending events to and handling received events from that server.
  #
  # A {Client} is not threadsafe; both the {Client} and any {Channel}s linked
  # to it should not be shared between threads. If they are shared without
  # appropriate locking mechanisms, the behavior is undefined and might result
  # in catastrophic process failures like segmentation faults in the underlying
  # C library. A {Client} can be safely used in a multithreaded application by
  # only passing control and message data between threads.
  #
  # To use a {Client} effectively, it is necessary to understand the
  # methods available in the underlying AMQP protocol. Please refer to
  # the protocol documentation for more information about specific methods:
  # http://www.rabbitmq.com/amqp-0-9-1-reference.html
  #
  class Client
    
    # Create a new {Client} instance with the given properties.
    # There are several ways to convey connection info:
    #
    # @example with a URL string
    #  RabbitMQ::Client.new("amqp://user:password@host:1234/vhost")
    #
    # @example with explicit options
    #  RabbitMQ::Client.new(user: "user", password: "password", port: 1234)
    #
    # @example with both URL string and explicit options
    #  RabbitMQ::Client.new("amqp://host:1234", user: "user", password: "password")
    #
    # Parsed options from a URL will be applied first, then any options given
    # explicitly will override those parsed. If any options are ambiguous, they
    # will have the default values:
    #   {
    #     user:           "guest",
    #     password:       "guest",
    #     host:           "localhost",
    #     vhost:          "/",
    #     port:           5672,
    #     ssl:            false,
    #     max_channels:   RabbitMQ::FFI::CHANNEL_MAX_ID, # absolute maximum
    #     max_frame_size: 131072,
    #   }
    #
    def initialize(*args)
      @conn = Connection.new(*args)
      
      @open_channels     = {}
      @released_channels = {}
      @event_handlers    = Hash.new { |h,k| h[k] = {} }
      @incoming_events   = Hash.new { |h,k| h[k] = {} }
      
      @protocol_timeout  = DEFAULT_PROTOCOL_TIMEOUT
    end
    
    # Initiate the connection with the server. It is necessary to call this
    # before any other communication, including creating a {#channel}. 
    def start
      close # Close if already open
      @conn.start
      self
    end
    
    # Gracefully close the connection with the server. This will
    # be done automatically on garbage collection if not called explicitly.
    def close
      @conn.close
      release_all_channels
      self
    end
    
    # Free the native resources associated with this object. This will
    # be done automatically on garbage collection if not called explicitly.
    def destroy
      @conn.destroy
      self
    end
    
    # The timeout to use when waiting for protocol events, in seconds.
    # By default, this has the value of {DEFAULT_PROTOCOL_TIMEOUT}.
    # When set, it affects operations like {#fetch_response} and {#run_loop!}.
    attr_accessor :protocol_timeout
    DEFAULT_PROTOCOL_TIMEOUT = 30 # seconds
    
    def user;           @conn.options.fetch(:user);           end
    def password;       @conn.options.fetch(:password);       end
    def host;           @conn.options.fetch(:host);           end
    def vhost;          @conn.options.fetch(:vhost);          end
    def port;           @conn.options.fetch(:port);           end
    def ssl?;           @conn.options.fetch(:ssl);            end
    def max_channels;   @conn.options.fetch(:max_channels);   end
    def max_frame_size; @conn.options.fetch(:max_frame_size); end
    
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
    def fetch_response(channel_id, method, timeout: protocol_timeout)
      methods = Array(method).map(&:to_sym)
      timeout = Float(timeout) if timeout
      fetch_response_internal(Integer(channel_id), methods, timeout)
    end
    
    # Register a handler for events on the given channel of the given type.
    # Only one handler for each event type may be registered at a time.
    # If no callable or block is given, the handler will be cleared.
    #
    # @param channel_id [Integer] The channel number to watch for.
    # @param method [Symbol] The type of protocol method to watch for.
    # @param callable [#call,nil] The callable handler if no block is given.
    # @param block [Proc,nil] The handler block to register.
    # @return [Proc,#call,nil] The given block or callable.
    # @yieldparam event [Hash] The event passed to the handler.
    #
    def on_event(channel_id, method, callable=nil, &block)
      handler = block || callable
      raise ArgumentError, "expected block or callable as the event handler" \
        unless handler.respond_to?(:call)
      
      @event_handlers[Integer(channel_id)][method.to_sym] = handler
      handler
    end
    
    # Unregister the event handler associated with the given channel and method.
    #
    # @param channel_id [Integer] The channel number to watch for.
    # @param method [Symbol] The type of protocol method to watch for.
    # @return [Proc,nil] This removed handler, if any.
    #
    def clear_event_handler(channel_id, method)
      @event_handlers[Integer(channel_id)].delete(method.to_sym)
    end
    
    # Fetch and handle events in a loop that blocks the calling thread.
    # The loop will continue until the {#break!} method is called from within
    # an event handler, or until the given timeout duration has elapsed.
    #
    # @param timeout [Float] the maximum time to run the loop, in seconds;
    #   if none is given, the value is {#protocol_timeout} or until {#break!}
    # @param block [Proc,nil] if given, the block will be yielded each
    #   non-exception event received on any channel. Other handlers or
    #   response fetchings that match the event will still be processed,
    #   as the block does not consume the event or replace the handlers.
    # @return [undefined] assume no value - reserved for future use.
    #
    def run_loop!(timeout: protocol_timeout, &block)
      timeout = Float(timeout) if timeout
      @breaking = false
      fetch_events(timeout, &block)
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
    
    # Open a new channel of communication and return a new {Channel} object
    # with convenience methods for communicating on that channel. The
    # channel will be automatically released if the {Channel} instance is
    # garbage collected, or if the {Client} connection is {#close}d.
    #
    # @param id [Integer,nil] The channel id number to use. If nil or not
    #   given, a unique channel number will be chosen automatically.
    # @raise [ArgumentError] If the given channel id number is not unique or
    #   if the given channel id number is greater than {#max_channels}.
    # @return [Channel] The new channel handle.
    #
    def channel(id=nil)
      id = allocate_channel(id)
      finalizer = Proc.new { release_channel(id) }
      Channel.new(self, @conn, id, finalizer)
    end
    
    # Open the specified channel.
    private def open_channel(id)
      Util.error_check :"opening a new channel",
        @conn.send_method(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
    end
    
    # Re-open the specified channel after unexpected closure.
    private def reopen_channel(id)
      Util.error_check :"acknowledging server-initated channel closure",
        @conn.send_method(id, :channel_close_ok)
      
      Util.error_check :"reopening channel after server-initated closure",
        @conn.send_method(id, :channel_open)
      
      fetch_response(id, :channel_open_ok)
    end
    
    # Verify or choose a channel id number that is available for use.
    private def allocate_channel(id=nil)
      if id
        id = Integer(id)
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
    
    # Release the given channel id to be reused later and clear its handlers.
    private def release_channel(id)
      @open_channels.delete(id)
      @event_handlers.delete(id)
      @released_channels[id] = true
    end
    
    # Release all channel ids to be reused later.
    private def release_all_channels
      @open_channels.clear
      @event_handlers.clear
      @released_channels.clear
    end
    
    # Execute the handler for this type of event, if any.
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
    
    # Internal implementation of the {#run_loop!} method.
    private def fetch_events(timeout=protocol_timeout, start=Time.now)
      @conn.garbage_collect
      
      while (event = @conn.fetch_next_event(timeout, start))
        handle_incoming_event(event)
        store_incoming_event(event)
        yield event if block_given?
        break if @breaking
      end
    end
    
    # Internal implementation of the {#fetch_response} method.
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
