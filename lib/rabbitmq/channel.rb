
module RabbitMQ
  class Channel
    
    attr_reader :connection
    attr_reader :id
    
    def initialize(connection, id)
      @connection = connection
      @id         = id
      connection.send(:open_channel!, id)
    end
    
  end
end
