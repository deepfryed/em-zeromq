require 'helper'

describe 'em-zeromq socket' do

  it 'should implement accessors for zmq socket attributes' do
    EM.run do
      rep = context.socket(ZMQ::REP).bind('tcp://*:5555')

      attributes = %w{
        hwm swap affinity identity sndbuf rcvbuf rate recovery_ivl
        mcast_loop linger reconnect_ivl reconnect_ivl_max backlog
      }

      assert_equal 1_000_000, rep.socket.get_hwm # default high water mark

      schedule(0.1) do
        attributes.each do |name|
          assert_respond_to rep.socket, "get_#{name}"
          assert_respond_to rep.socket, "set_#{name}"
        end
      end
    end
  end
end
