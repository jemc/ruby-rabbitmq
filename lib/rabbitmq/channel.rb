
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
    
    private def rpc(kls, params=[{}], expect:nil)
      req = FFI::Method.lookup_class(kls).new
      req.apply(params.last)
      
      Util.error_check :"sending a request on a channel",
        @connection.send(:send_method, @id, req)
      
      res = @connection.send(:fetch_event_for_channel, @id)
      
      raise FFI::Error::Timeout, "waiting for response to #{req.class}" unless res
      if expect
        expect_kls = FFI::Method.lookup_class(expect)
        raise FFI::Error::WrongMethod,
          "response to #{req.class} =>\n#{res.describe}" \
            unless res.is_a?(expect_kls)
      end
      
      res.to_h
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
    
  end
end
