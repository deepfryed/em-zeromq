require 'minitest/spec'
require 'minitest/autorun'
require 'em-zeromq'

class MiniTest::Spec
  def context
    @@context ||= EM::ZeroMQ::Context.new(3)
  end

  def schedule secs, &block
    EM.defer do
      block.call
      EM.add_timer(secs) { EM.stop }
    end
  end
end

class TestHandler < EM::ZeroMQ::Connection
  def self.messages
    @messages ||= []
  end

  def on_readable m
    self.class.messages << m
  end
end
