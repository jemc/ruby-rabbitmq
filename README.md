# rabbitmq

[![Build Status](https://circleci.com/gh/jemc/ruby-rabbitmq/tree/master.svg?style=svg)](https://circleci.com/gh/jemc/ruby-rabbitmq/tree/master) 
[![Gem Version](https://badge.fury.io/rb/rabbitmq.png)](http://badge.fury.io/rb/rabbitmq) 
[![Join the chat at https://gitter.im/jemc/ruby-rabbitmq](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jemc/ruby-rabbitmq?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A Ruby RabbitMQ client library based on FFI bindings for [librabbitmq](https://github.com/alanxz/rabbitmq-c).

## Design Goals

- Provide a minimal API for creating useful RabbitMQ applications in Ruby.
- Use a minimal resource and execution path footprint.
- No library-imposed background or watchdog threads.
- Favor directness over convenience.
- Use an existing protocol library (librabbitmq) instead of reinventing one.
- Avoid making precluding assumptions about what a user needs.

## Who should use this library?

This library was born out dissatisfaction with some of the design decisions made by existing RabbitMQ client libraries for Ruby and the lack of flexibility those libraries afforded to their users in deciding how best to integrate RabbitMQ into their application. This library is for users who know what they want, know the patterns they need to use from RabbitMQ best practices, and want to proceed with a library that provides them the minimal platform they need without getting in their way.

This library runs no background threads and leaves it up to the user to explicitly invoke the RabbitMQ event loop as a part of their application. This library aims to be easy to integrate with any sensible event processing framework or pattern, or to act as the main event loop driver itself. Users should know what kind of patterns they wish to use, and understand how they can use blocking calls, nonblocking calls, and/or timeouts to implement their application elegantly and efficiently.

This library does not provide thread-safe client objects. Multithreaded applications should pass data between threads instead of sharing client objects between threads. Not supporting concurrent access to connection state is consistent with the underlying C library and allows for less obfuscation in the codebase and better efficiency, avoiding the costs of acquiring locks and passing through session changes. Users should be comfortable with code patterns that prevent unwanted sharing of the client objects, as doing so may cause catastrophic application failures like segmentation faults in the underlying C library.

## Usage

To use this library effectively, it is necessary to understand the possibilities and idioms of RabbitMQ. Users are encouraged to familiarize themselves with the [AMQP protocol reference documentation](http://www.rabbitmq.com/amqp-0-9-1-reference.html).

```bash
$ gem install rabbitmq -v 1.0.0-pre
$ ruby examples/publish_500.rb
$ ruby examples/consume_500.rb
```

```ruby
# examples/publish_500.rb
require 'rabbitmq'

publisher = RabbitMQ::Client.new.start.channel
queue     = "some_queue"
exchange  = "" # default exchange
publisher.queue_delete(queue)
publisher.queue_declare(queue)

500.times do |i|
  publisher.basic_publish("message #{i}", exchange, queue, persistent: true)
end
```

```ruby
# examples/consume_500.rb
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
```

## Contributing

Performance and implementation improvements, bug fixes, and documentation expansions are always welcome! Create a patch or pull request with a focused approach that solves exactly one problem, and it's very likely to be pulled in.

For new features, please file an issue ticket explaining the use case and why the new feature should be a part of this library rather than a part of a separate wrapper or convenience library. If a feature meets the design goals of the project and is not yet implemented (such as SSL support, or other missing primitives critical to certain applications), it's likely to be approved quickly.
