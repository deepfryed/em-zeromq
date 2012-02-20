# em-zeromq

A simple zeromq binding running on eventmachine.

## Dependencies

* zmq
* eventmachine

## Example

```ruby
require 'em-zeromq'

class MyHandler < EM::ZeroMQ::Connection
  def on_readable message
    puts message
  end
end

EM.run do
  context    = EM::ZeroMQ::Context.new
  publisher  = context.socket(ZMQ::PUB).bind('tcp://*:5555', EM::ZeroMQ::Connection)
  subscriber = context.socket(ZMQ::SUB) do
    subscribe('')
    connect('tcp://*:5555', MyHandler)
  end

  EM.add_periodic_timer(1) do
    publisher.send("hello")
  end
end
```

# See Also
[https://github.com/andrewvc/em-zeromq](https://github.com/andrewvc/em-zeromq)

# License
[Creative Commons Attribution - CC BY](http://creativecommons.org/licenses/by/3.0)
