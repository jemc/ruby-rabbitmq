
require 'rabbitmq'

consumer = RabbitMQ::Client.new.start.channel
consumer.basic_qos(prefetch_count: 500)
consumer.basic_consume("some_queue")

count = 0
consumer.on :basic_deliver do |message|
  puts message[:body]
  if (count += 1) >= 500
    consumer.basic_ack(message[:properties][:delivery_tag], multiple: true)
    consumer.break!
  end
end

consumer.run_loop!
