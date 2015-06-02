
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
    
    def queue_declare(name, opts={})
      rpc :queue_declare, [
        queue:       name,
        passive:     opts.fetch(:passive,     false),
        durable:     opts.fetch(:durable,     false),
        exclusive:   opts.fetch(:exclusive,   false),
        auto_delete: opts.fetch(:auto_delete, false),
      ], expect: :queue_declare_ok
    end
    
  end
end
