
require 'rabbitmq'

# Consume batches of messages in a loop indefinitely,
# showing memory usage and other stats in between each batch.

batch_count = 500 # number of messages to fetch for each batch
sleep_time  = 0.1 # time in seconds to sleep in between each batch

consumer = RabbitMQ::Client.new.start.channel
consumer.basic_qos(prefetch_count: batch_count)
consumer.basic_consume("memory_queue")

count = 0
consumer.on :basic_deliver do |message|
  if (count += 1) >= batch_count
    consumer.basic_ack(message[:properties][:delivery_tag], multiple: true)
    
    system "ps -u --pid #{Process.pid}"; puts
    sleep sleep_time
    count = 0
  end
end

consumer.run_loop!
