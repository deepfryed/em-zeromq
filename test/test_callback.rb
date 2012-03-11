require 'helper'

describe 'em-zeromq callback without connection subclass' do

  it 'should work' do
    handler = Class.new do
      def messages
        @messages ||= []
      end

      def on_readable c, m
        messages << m
        c.unbind if messages.size > 3
        c.send('hello')
      end

      def on_writable c
      end
    end

    object = handler.new

    EM.run do
      rep = context.socket(ZMQ::REP, object).bind('tcp://*:5555')
      req = context.socket(ZMQ::REQ, object).connect('tcp://*:5555')

      schedule(0.1) do
        req.send('hi')
      end
    end

    assert_equal %w(hi hello hello hello), object.messages.flatten
  end
end
