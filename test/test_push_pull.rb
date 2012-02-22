require 'helper'

describe 'em-zeromq push pull' do

  it 'should work' do
    messages = []
    handler  = Class.new(TestHandler)

    EM.run do
      push = context.socket(ZMQ::PUSH).bind('tcp://*:5555')
      pull = context.socket(ZMQ::PULL).connect('tcp://*:5555', handler)

      schedule(0.05) do
        5.times { push.send('hello') }
      end
    end

    assert_equal 5,       handler.messages.size
    assert_equal 'hello', handler.messages.first
  end
end
