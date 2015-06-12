
module RabbitMQ
  class Channel
    
    attr_reader :client
    attr_reader :id
    
    # Don't create a {Channel} directly; call {Client#channel} instead.
    # @api private
    def initialize(client, conn, id, finalizer)
      @client    = client
      @conn      = conn
      @id        = id
      @finalizer = finalizer
      ObjectSpace.define_finalizer self, @finalizer
    end
    
    # Release the channel id to be reallocated to another {Channel} instance.
    # This will be called automatically by the object finalizer after
    # the object becomes unreachable by the VM and is garbage collected,
    # but you may want to call it explicitly if you plan to reuse the same
    # channel id in another {Channel} instance explicitly.
    #
    # @return [Channel] self.
    #
    def release
      if @finalizer
        @finalizer.call
        ObjectSpace.undefine_finalizer self
      end
      @finalizer = nil
      
      self
    end
    
    # @see {Client#send_request}
    def send_request(*args)
      @client.send_request(@id, *args)
    end
    
    # @see {Client#fetch_response}
    def fetch_response(*args)
      @client.fetch_response(@id, *args)
    end
    
    # @see {Client#on_event}
    def on_event(*args, &block)
      @client.on_event(@id, *args, &block)
    end
    alias_method :on, :on_event
    
    # @see {Client#run_loop!}
    # The block will be yielded all non-exception events *for any channel*.
    def run_loop!(*args, &block)
      @client.run_loop!(*args, &block)
    end
    
    # @see {Client#break!}
    def break!
      @client.break!
    end
    
    ##
    # Exchange operations
    
    def exchange_declare(name, type, **opts)
      send_request :exchange_declare, {
        exchange:    name,
        type:        type,
        passive:     opts.fetch(:passive,     false),
        durable:     opts.fetch(:durable,     false),
        auto_delete: opts.fetch(:auto_delete, false),
        internal:    opts.fetch(:internal,    false),
      }
      fetch_response :exchange_declare_ok
    end
    
    def exchange_delete(name, **opts)
      send_request :exchange_delete, {
        exchange:  name,
        if_unused: opts.fetch(:if_unused, false)
      }
      fetch_response :exchange_delete_ok
    end
    
    def exchange_bind(source, destination, **opts)
      send_request :exchange_bind, {
        source:      source,
        destination: destination,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {})
      }
      fetch_response :exchange_bind_ok
    end
    
    def exchange_unbind(source, destination, **opts)
      send_request :exchange_unbind, {
        source:      source,
        destination: destination,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {})
      }
      fetch_response :exchange_unbind_ok
    end
    
    ##
    # Queue operations
    
    def queue_declare(name, **opts)
      send_request :queue_declare, {
        queue:       name,
        passive:     opts.fetch(:passive,     false),
        durable:     opts.fetch(:durable,     false),
        exclusive:   opts.fetch(:exclusive,   false),
        auto_delete: opts.fetch(:auto_delete, false),
        arguments:   opts.fetch(:arguments,   {})
      }
      fetch_response :queue_declare_ok
    end
    
    def queue_bind(name, exchange, **opts)
      send_request :queue_bind, {
        queue:       name,
        exchange:    exchange,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {})
      }
      fetch_response :queue_bind_ok
    end
    
    def queue_unbind(name, exchange, **opts)
      send_request :queue_unbind, {
        queue:       name,
        exchange:    exchange,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {})
      }
      fetch_response :queue_unbind_ok
    end
    
    def queue_purge(name)
      send_request :queue_purge, { queue: name }
      fetch_response :queue_purge_ok
    end
    
    def queue_delete(name, **opts)
      send_request :queue_delete, {
        queue:     name,
        if_unused: opts.fetch(:if_unused, false),
        if_empty:  opts.fetch(:if_empty,  false)
      }
      fetch_response :queue_delete_ok
    end
    
    ##
    # Consumer operations
    
    def basic_qos(**opts)
      send_request :basic_qos, {
        prefetch_count: opts.fetch(:prefetch_count, 0),
        prefetch_size:  opts.fetch(:prefetch_size,  0),
        global:         opts.fetch(:global,         false)
      }
      fetch_response :basic_qos_ok
    end
    
    def basic_consume(queue, consumer_tag="", **opts)
      send_request :basic_consume, {
        queue:        queue,
        consumer_tag: consumer_tag,
        no_local:     opts.fetch(:no_local,  false),
        no_ack:       opts.fetch(:no_ack,    false),
        exclusive:    opts.fetch(:exclusive, false),
        arguments:    opts.fetch(:arguments, {})
      }
      fetch_response :basic_consume_ok
    end
    
    def basic_cancel(consumer_tag)
      send_request :basic_cancel, { consumer_tag: consumer_tag }
      fetch_response :basic_cancel_ok
    end
    
    ##
    # Transaction operations
    
    def tx_select
      send_request :tx_select
      fetch_response :tx_select_ok
    end
    
    def tx_commit
      send_request :tx_commit
      fetch_response :tx_commit_ok
    end
    
    def tx_rollback
      send_request :tx_rollback
      fetch_response :tx_rollback_ok
    end
    
    ##
    # Message operations
    
    def basic_get(queue, **opts)
      send_request :basic_get, {
        queue:  queue,
        no_ack: opts.fetch(:no_ack, false)
      }
      fetch_response [:basic_get_ok, :basic_get_empty]
    end
    
    def basic_ack(delivery_tag, **opts)
      send_request :basic_ack, {
        delivery_tag: delivery_tag,
        multiple:     opts.fetch(:multiple, false)
      }
      true
    end
    
    def basic_nack(delivery_tag, **opts)
      send_request :basic_nack, {
        delivery_tag: delivery_tag,
        multiple:     opts.fetch(:multiple, false),
        requeue:      opts.fetch(:requeue, true)
      }
      true
    end
    
    def basic_reject(delivery_tag, **opts)
      send_request :basic_reject, {
        delivery_tag: delivery_tag,
        requeue:      opts.fetch(:requeue, true)
      }
      true
    end
    
    def basic_publish(body, exchange, routing_key, **opts)
      body        = FFI::Bytes.from_s(body.to_s)
      exchange    = FFI::Bytes.from_s(exchange.to_s)
      routing_key = FFI::Bytes.from_s(routing_key.to_s)
      properties  = FFI::BasicProperties.new.apply(
        content_type:       opts.fetch(:content_type,     nil),
        content_encoding:   opts.fetch(:content_encoding, nil),
        headers:            opts.fetch(:headers,           {}),
        delivery_mode:     (opts.fetch(:persistent,     false) ? :persistent : :nonpersistent),
        priority:           opts.fetch(:priority,           0),
        correlation_id:     opts.fetch(:correlation_id,   nil),
        reply_to:           opts.fetch(:reply_to,         nil),
        expiration:         opts.fetch(:expiration,       nil),
        message_id:         opts.fetch(:message_id,       nil),
        timestamp:          opts.fetch(:timestamp,          0),
        type:               opts.fetch(:type,             nil),
        app_id:             opts.fetch(:app_id,           nil),
        cluster_id:         opts.fetch(:cluster_id,       nil)
      )
      
      Util.error_check :"publishing a message",
        FFI.amqp_basic_publish(@conn.ptr, @id,
          exchange,
          routing_key,
          opts.fetch(:mandatory, false),
          opts.fetch(:immediate, false),
          properties,
          body
        )
      
      body.free!
      exchange.free!
      routing_key.free!
      properties.free!
      true
    end
    
  end
end
