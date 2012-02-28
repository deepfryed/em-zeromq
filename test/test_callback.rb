require 'helper'

describe 'em-zeromq callback without connection subclass' do

  it 'should work' do
    messages = []
    handler  = Class.new do
      def messages
        @messages ||= []
      end

      def on_readable c, m
        messages << m
      end

      def on_writable c
      end
    end

    object = handler.new


    EM.run do

      pub1 = context.socket(ZMQ::PUB).bind('tcp://*:5555')
      pub2 = context.socket(ZMQ::PUB).bind('tcp://*:5556')

      context.socket(ZMQ::SUB, object) do |socket|
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

    assert_equal 10, object.messages.size
    assert_equal [%w(p1), %w(p2)], object.messages.uniq.sort
  end
end
