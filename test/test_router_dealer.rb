require 'helper'

describe 'em-zeromq router dealerl' do

  it 'should work with router-dealer' do
    messages = []
    handler  = Class.new(TestHandler)

    EM.run do
      router = context.socket(ZMQ::ROUTER) do |socket|
        socket.set_identity('router1')
        socket.bind('tcp://*:5555')
      end

      dealer = context.socket(ZMQ::DEALER, handler) do |socket|
        socket.set_identity('dealer1')
        socket.connect('tcp://*:5555')
      end

      schedule(0.2) do
        5.times { router.send(['dealer1', 'hello'])}
      end
    end

    assert_equal 5,       handler.messages.size
    assert_equal 'hello', handler.messages.first
  end

  it 'should work with router-rep' do
    messages = []
    handler  = Class.new(TestHandler) do
      def on_readable message
        send("re:#{message}")
        super
      end
    end

    EM.run do
      dealer = context.socket(ZMQ::DEALER) do |socket|
        socket.set_identity('dealer1')
        socket.connect('tcp://*:5555')
      end

      rep = context.socket(ZMQ::REP, handler) do |socket|
        socket.set_identity('rep1')
        socket.bind('tcp://*:5555')
      end

      schedule(0.2) do
        5.times { dealer.send(['rep1', '', 'hello'])}
      end
    end

    assert_equal 5,       handler.messages.size
    assert_equal 'hello', handler.messages.first
  end
end
