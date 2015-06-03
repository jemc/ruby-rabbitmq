
module RabbitMQ
  class Channel
    
    attr_reader :connection
    attr_reader :id
    
    def initialize(connection, id, pre_allocated: false)
      @connection = connection
      @id         = id
      connection.send(:allocate_channel, id) unless pre_allocated
      
      @finalizer = self.class.send :create_finalizer_for, @connection, @id
      ObjectSpace.define_finalizer self, @finalizer
    end
    
    def release
      if @finalizer
        @finalizer.call
        ObjectSpace.undefine_finalizer self
      end
      @finalizer = nil
      
      self
    end
    
    # @private
    def self.create_finalizer_for(connection, id)
      Proc.new do
        connection.send(:release_channel, id)
      end
    end
    
    private def rpc(req_type, params=[{}], expect:nil)
      properties = params.last
      
      Util.error_check :"sending a request on a channel",
        @connection.send(:send_method, @id, req_type, properties)
      
      res = @connection.send(:fetch_event_for_channel, @id)
      raise FFI::Error::Timeout, "waiting for response to #{req_type}" unless res
      
      raise FFI::Error::WrongMethod,
        "response to #{req_type} => #{res.inspect}" \
          if expect && res.fetch(:method) != expect
      
      res
    end
    
    ##
    # Exchange operations
    
    def exchange_declare(name, type, **opts)
      rpc :exchange_declare, [
        exchange:    name,
        type:        type,
        passive:     opts.fetch(:passive,     false),
        durable:     opts.fetch(:durable,     false),
        auto_delete: opts.fetch(:auto_delete, false),
        internal:    opts.fetch(:internal,    false),
      ], expect: :exchange_declare_ok
    end
    
    def exchange_delete(name, **opts)
      rpc :exchange_delete, [
        exchange:  name,
        if_unused: opts.fetch(:if_unused, false),
      ], expect: :exchange_delete_ok
    end
    
    def exchange_bind(source, destination, **opts)
      rpc :exchange_bind, [
        source:      source,
        destination: destination,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {}),
      ], expect: :exchange_bind_ok
    end
    
    def exchange_unbind(source, destination, **opts)
      rpc :exchange_unbind, [
        source:      source,
        destination: destination,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {}),
      ], expect: :exchange_unbind_ok
    end
    
    ##
    # Queue operations
    
    def queue_declare(name, **opts)
      rpc :queue_declare, [
        queue:       name,
        passive:     opts.fetch(:passive,     false),
        durable:     opts.fetch(:durable,     false),
        exclusive:   opts.fetch(:exclusive,   false),
        auto_delete: opts.fetch(:auto_delete, false),
        arguments:   opts.fetch(:arguments,   {}),
      ], expect: :queue_declare_ok
    end
    
    def queue_bind(name, exchange, **opts)
      rpc :queue_bind, [
        queue:       name,
        exchange:    exchange,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {}),
      ], expect: :queue_bind_ok
    end
    
    def queue_unbind(name, exchange, **opts)
      rpc :queue_unbind, [
        queue:       name,
        exchange:    exchange,
        routing_key: opts.fetch(:routing_key, ""),
        arguments:   opts.fetch(:arguments,   {}),
      ], expect: :queue_unbind_ok
    end
    
    def queue_purge(name)
      rpc :queue_purge, [queue: name], expect: :queue_purge_ok
    end
    
    def queue_delete(name, **opts)
      rpc :queue_delete, [
        queue:     name,
        if_unused: opts.fetch(:if_unused, false),
        if_empty:  opts.fetch(:if_empty,  false),
      ], expect: :queue_delete_ok
    end
    
    ##
    # Consumer operations
    
    def basic_qos(**opts)
      rpc :basic_qos, [
        prefetch_count: opts.fetch(:prefetch_count, 0),
        prefetch_size:  opts.fetch(:prefetch_size,  0),
        global:         opts.fetch(:global,         false),
      ], expect: :basic_qos_ok
    end
    
    def basic_consume(queue, consumer_tag="", **opts)
      rpc :basic_consume, [
        queue:        queue,
        consumer_tag: consumer_tag,
        no_local:     opts.fetch(:no_local,  false),
        no_ack:       opts.fetch(:no_ack,    false),
        exclusive:    opts.fetch(:exclusive, false),
        arguments:    opts.fetch(:arguments, {}),
      ], expect: :basic_consume_ok
    end
    
    def basic_cancel(consumer_tag)
      rpc :basic_cancel, [consumer_tag: consumer_tag], expect: :basic_cancel_ok
    end
    
    ##
    # Transaction operations
    
    def tx_select
      rpc :tx_select, expect: :tx_select_ok
    end
    
    def tx_commit
      rpc :tx_commit, expect: :tx_commit_ok
    end
    
    def tx_rollback
      rpc :tx_rollback, expect: :tx_rollback_ok
    end
    
    ##
    # Message operations
    
    def basic_get(queue, **opts)
      rpc :basic_get, [
        queue:  queue,
        no_ack: opts.fetch(:no_ack, false),
      ], expect: :basic_get_ok
    end
    
    def basic_publish(body, exchange, routing_key, **opts)
      body        = FFI::Bytes.from_s(body, true)
      exchange    = FFI::Bytes.from_s(exchange, true)
      routing_key = FFI::Bytes.from_s(routing_key, true)
      properties  = FFI::BasicProperties.new.apply(
        content_type:       opts.fetch(:content_type,     "application/octet-stream"),
        content_encoding:   opts.fetch(:content_encoding, ""),
        headers:            opts.fetch(:headers,          {}),
        delivery_mode:     (opts.fetch(:persistent,    false) ? :persistent : :nonpersistent),
        priority:           opts.fetch(:priority,          0),
        correlation_id:     opts.fetch(:correlation_id,   ""),
        reply_to:           opts.fetch(:reply_to,         ""),
        expiration:         opts.fetch(:expiration,       ""),
        message_id:         opts.fetch(:message_id,       ""),
        timestamp:          opts.fetch(:timestamp,         0),
        type:               opts.fetch(:type,             ""),
        user_id:            opts.fetch(:user_id,          ""),
        app_id:             opts.fetch(:app_id,           ""),
        cluster_id:         opts.fetch(:cluster_id,       "")
      )
      
      Util.error_check :"publishing a message",
        FFI.amqp_basic_publish(connection.send(:ptr), @id,
          exchange,
          routing_key,
          opts.fetch(:mandatory, false),
          opts.fetch(:immediate, false),
          properties,
          body
        )
      
      properties.free!
      true
    end
    
  end
end
