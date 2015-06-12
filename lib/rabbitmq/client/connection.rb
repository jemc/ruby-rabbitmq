
require 'socket'

module RabbitMQ
  class Client
    
    class DestroyedError < RuntimeError; end
    
    class Connection
      
      attr_reader :ptr
      
      def initialize(client)
        @client = client
        @frame = FFI::Frame.new
        @ptr = FFI.amqp_new_connection
        
        create_socket!
        
        @finalizer = self.class.create_finalizer_for(@ptr)
        ObjectSpace.define_finalizer(self, @finalizer)
      end
      
      def destroy
        if @finalizer
          @finalizer.call
          ObjectSpace.undefine_finalizer(self)
        end
        @ptr = @socket = @finalizer = nil
      end
      
      # @private
      def self.create_finalizer_for(ptr)
        Proc.new do
          FFI.amqp_connection_close(ptr, 200)
          FFI.amqp_destroy_connection(ptr)
        end
      end
      
      def ptr
        raise DestroyedError unless @ptr
        @ptr
      end
      
      def close
        raise DestroyedError unless @ptr
        FFI.amqp_connection_close(@ptr, 200)
      end
      
      def create_socket!
        raise DestroyedError unless @ptr
        
        @socket = FFI.amqp_tcp_socket_new(@ptr)
        Util.null_check :"creating a socket", @socket
      end
      
      def connect_socket!
        raise DestroyedError unless @ptr
        raise NotImplementedError if @client.ssl?
        
        create_socket!
        Util.error_check :"opening a socket",
          FFI.amqp_socket_open(@socket, @client.host, @client.port)
        
        @ruby_socket = Socket.for_fd(FFI.amqp_get_sockfd(@ptr))
        @ruby_socket.autoclose = false
      end
      
      def login!
        raise DestroyedError unless @ptr
        
        res = FFI.amqp_login(@ptr, @client.vhost,
          @client.max_channels, @client.max_frame_size,
          @client.heartbeat_interval, :plain,
          :string, @client.user, :string, @client.password)
        
        case res[:reply_type]
        when :library_exception; Util.error_check :"logging in", res[:library_error]
        when :server_exception;  raise NotImplementedError
        end
        
        @server_properties = FFI::Table.new(FFI.amqp_get_server_properties(@ptr)).to_h
      end
      
      # Block until there is readable data on the internal ruby socket,
      # returning true if there is readable data, or false if time expired.
      def select(timeout=0, start=Time.now)
        if timeout
          timeout = timeout - (start-Time.now)
          timeout = 0 if timeout < 0
        end
        
        IO.select([@ruby_socket], [], [], timeout) ? true : false
      end
      
      # Return the next available frame, or nil if time expired.
      def fetch_next_frame(timeout=0, start=Time.now)
        frame = @frame
        
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
      def fetch_next_event(timeout=0, start=Time.now)
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
      
      def send_method(channel_id, method, properties={})
        req    = FFI::Method.lookup_class(method).new.apply(properties)
        status = FFI.amqp_send_method(ptr, channel_id, method, req.pointer)
        
        req.free!
        status
      end
      
      def garbage_collect
        FFI.amqp_maybe_release_buffers(ptr)
      end
      
      def garbage_collect_channel(channel_id)
        FFI.amqp_maybe_release_buffers_on_channel(ptr, channel_id)
      end
    end
    
  end
end
