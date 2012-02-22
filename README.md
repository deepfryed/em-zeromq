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
  subscriber = context.socket(ZMQ::SUB) do |socket|
    socket.subscribe('')
    socket.connect('tcp://*:5555', MyHandler)
  end

  EM.add_periodic_timer(1) do
    publisher.send("hello")
  end
end
```

## Reference
[ØMQ/2.1.11 API Reference](http://api.zeromq.org/)

## API

```
EM::ZeroMQ::Context

public:

  .new(threads)
  #socket(type, handler = nil, *args)

EM::ZeroMQ::Socket

public:

  #bind(address)
  #connect(address)
  #subscribe(what)
  #unsubscribe(what)
  #send(message)
  #attach(handler, *args)

  #get_hwm
  #set_hwm(value)
  #get_swap
  #set_swap(value)
  #get_affinity
  #set_affinity(value)
  #get_identity
  #set_identity(value)
  #get_sndbuf
  #set_sndbuf(value)
  #get_rcvbuf
  #set_rcvbuf(value)
  #get_rate
  #set_rate(value)
  #get_recovery_ivl
  #set_recovery_ivl(value)
  #get_mcast_loop
  #set_mcast_loop(value)
  #get_linger
  #set_linger(value)
  #get_reconnect_ivl
  #set_reconnect_ivl(value)
  #get_reconnect_ivl_max
  #set_reconnect_ivl_max(value)
  #get_backlog
  #set_backlog(value)
 
semi-public: 
  #readable?
  #writable?
  #message_parts?
  #recv

EM::ZeroMQ::Connection

public:

  #on_readable
  #on_writable
  #send(message)
```

# See Also
[https://github.com/andrewvc/em-zeromq](https://github.com/andrewvc/em-zeromq)

# License
[Creative Commons Attribution - CC BY](http://creativecommons.org/licenses/by/3.0)
