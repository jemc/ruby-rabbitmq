
require_relative 'rabbitmq/util'

require_relative 'rabbitmq/ffi'
require_relative 'rabbitmq/ffi/ext'
require_relative 'rabbitmq/ffi/error'

require_relative 'rabbitmq/server_error'

require_relative 'rabbitmq/client'
require_relative 'rabbitmq/channel'


module RabbitMQ
  # The RabbitMQ default exchange.
  DEFAULT_EXCHANGE = "".freeze
  
  # An array of errors that indicate an availabilty issue.
  AVAILABILITY_ERRORS = [
    RabbitMQ::ServerError::ConnectionError,
    RabbitMQ::FFI::Error::Timeout,
    RabbitMQ::FFI::Error::ConnectionClosed,
    RabbitMQ::FFI::Error::SocketError,
    RabbitMQ::FFI::Error::BadAmqpData,
  ].freeze
end
