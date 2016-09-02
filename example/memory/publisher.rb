
require 'rabbitmq'

# Publish batches of messages in a loop indefinitely,
# showing memory usage and other stats in between each batch.

batch_count = 500 # number of messages to fetch for each batch
sleep_time  = 0.1 # time in seconds to sleep in between each batch

publisher = RabbitMQ::Client.new.start.channel
queue     = "memory_queue"
exchange  = RabbitMQ::DEFAULT_EXCHANGE
publisher.queue_declare(queue)

while true
  batch_count.times do |i|
    publisher.basic_publish("message #{i} " * 100, exchange, queue)
  end
  system "ps -u --pid #{Process.pid}"; puts
  sleep sleep_time
end
