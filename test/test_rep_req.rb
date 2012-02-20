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
      rep = context.socket(ZMQ::REP).bind('tcp://*:5555',    handler1)
      req = context.socket(ZMQ::REQ).connect('tcp://*:5555', handler2)

      schedule(0.05) do
        5.times { req.send('hello') }
      end
    end

    assert_equal 5,       handler1.messages.size
    assert_equal 'hello', handler1.messages.first
    assert_equal 5,       handler2.messages.size
    assert_equal 'world', handler2.messages.first
  end
end
