
module RabbitMQ
  class ServerError < RuntimeError
    class << self
      attr_reader :lookup_table
    end
    
    def self.from(event)
      properties = event.fetch(:properties)
      kls = case event.fetch(:method)
      when :channel_close
        ChannelError.lookup_table[properties.fetch(:reply_code)]
      when :connection_close
        ConnectionError.lookup_table[properties.fetch(:reply_code)]
      else
        return
      end
      exc = kls.new(properties.fetch(:reply_text))
      exc.event = event
      exc
    end
    
    attr_writer :event
    
    class ChannelError < ServerError
      @lookup_table = {}
      {
        311 => :content_too_large,
        313 => :no_consumers,
        403 => :access_refused,
        404 => :not_found,
        405 => :resource_locked,
        406 => :precondition_failed,
      }.each do |code, name|
        kls = Class.new(self) { define_method(:code) { code } }
        @lookup_table[code] = kls
        const_set Util.const_name(name), kls
      end
    end
    
    class ConnectionError < ServerError
      @lookup_table = {}
      {
        320 => :connection_forced,
        402 => :invalid_path,
        501 => :frame_error,
        502 => :syntax_error,
        503 => :command_invalid,
        504 => :channel_error,
        505 => :unexpected_frame,
        506 => :resource_error,
        530 => :not_allowed,
        540 => :not_implemented,
        541 => :internal_error,
      }.each do |code, name|
        kls = Class.new(self) { define_method(:code) { code } }
        @lookup_table[code] = kls
        const_set Util.const_name(name), kls
      end
    end
  end
end
