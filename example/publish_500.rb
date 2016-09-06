
require 'rabbitmq'

publisher = RabbitMQ::Client.new.start.channel
queue     = "some_queue"
exchange  = RabbitMQ::DEFAULT_EXCHANGE
publisher.queue_delete(queue)
publisher.queue_declare(queue)

500.times do |i|
  publisher.basic_publish("message #{i}", exchange, queue, persistent: true)
end
