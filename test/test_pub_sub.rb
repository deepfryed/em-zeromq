require 'helper'

describe 'em-zeromq pub sub' do

  it 'should work' do
    messages = []
    handler  = Class.new(TestHandler)

    EM.run do
      pub = context.socket(ZMQ::PUB).bind('tcp://*:5555', handler)
      sub = context.socket(ZMQ::SUB).subscribe('').connect('tcp://*:5555', handler)

      schedule(0.05) do
        5.times { pub.send('hello') }
      end
    end

    assert_equal 5,       handler.messages.size
    assert_equal 'hello', handler.messages.first
  end
end
