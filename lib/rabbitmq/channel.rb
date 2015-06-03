
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
      req = FFI::Method.lookup_class(req_type).new
      req.apply(params.last)
      
      Util.error_check :"sending a request on a channel",
        @connection.send(:send_method, @id, req)
      
      res = @connection.send(:fetch_event_for_channel, @id)
      raise FFI::Error::Timeout, "waiting for response to #{req.class}" unless res
      
      raise FFI::Error::WrongMethod,
        "response to #{req_type} => #{res.fetch(:method)}\n#{res.inspect}" \
          if expect && res.fetch(:method) != expect
      
      res.fetch(:properties)
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
        no_local:     opts.fetch(:no_local,     false),
        no_ack:       opts.fetch(:no_ack,       false),
        exclusive:    opts.fetch(:exclusive,    false),
        arguments:    opts.fetch(:arguments,    {}),
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
    
  end
end
