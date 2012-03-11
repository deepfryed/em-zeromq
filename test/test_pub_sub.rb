require 'helper'

describe 'em-zeromq pub sub' do

  it 'should work' do
    handler = Class.new(TestHandler) do
      def on_readable m
        super
        socket.unsubscribe('') if self.class.messages.size == 10
      end
    end

    EM.run do

      pub1 = context.socket(ZMQ::PUB).bind('tcp://*:5555')
      pub2 = context.socket(ZMQ::PUB).bind('tcp://*:5556')
      context.socket(ZMQ::SUB, handler) do |socket|
        socket.subscribe('')
        socket.connect('tcp://*:5555')
        socket.connect('tcp://*:5556')
      end

      schedule(0.2) do
        5.times do
          pub1.send('p1')
          pub2.send('p2')
        end
      end
    end

    assert_equal 10, handler.messages.size
    assert_equal [%w(p1), %w(p2)], handler.messages.uniq.sort
  end
end
