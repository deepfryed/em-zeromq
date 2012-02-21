require 'helper'

describe 'em-zeromq pub sub' do

  it 'should work' do
    messages = []
    handler  = Class.new(TestHandler)

    EM.run do

      pub = context.socket(ZMQ::PUB) do |socket|
        socket.bind('tcp://*:5555', handler)
      end

      sub = context.socket(ZMQ::SUB) do |socket|
        socket.subscribe('')
        socket.connect('tcp://*:5555', handler)
      end

      schedule(0.1) do
        5.times { pub.send('hello') }
      end
    end

    assert_equal 5,       handler.messages.size
    assert_equal 'hello', handler.messages.first
  end
end
