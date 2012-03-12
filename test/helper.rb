require 'minitest/spec'
require 'simplecov'

# simplecov stuff needs to go here before autorun is called.
SimpleCov.start do
  add_filter '/test/'
end

# close context after all tests are done.
at_exit do
  MiniTest::Spec.context.close
end

require 'minitest/autorun'
require 'em-zeromq'

class MiniTest::Spec
  def self.context
    @@context ||= EM::ZeroMQ::Context.new(3)
  end

  def context
    MiniTest::Spec.context
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
