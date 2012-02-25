require 'helper'

describe 'em-zeromq rep req' do

  it 'should work' do
    messages = []
    handler1 = Class.new(TestHandler) do
      def on_readable message
        super
        send('world')
      end
    end

    handler2 = Class.new(TestHandler)

    EM.run do
      rep = context.socket(ZMQ::REP, handler1).bind('tcp://*:5555')
      req = context.socket(ZMQ::REQ, handler2).connect('tcp://*:5555')

      schedule(0.2) do
        5.times { req.send('hello') }
      end
    end

    assert_equal 5,       handler1.messages.size
    assert_equal 'hello', handler1.messages.first.first
    assert_equal 5,       handler2.messages.size
    assert_equal 'world', handler2.messages.first.first
  end
end
