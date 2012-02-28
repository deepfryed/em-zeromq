require 'zmq'
require 'eventmachine'

module EM::ZeroMQ

  VERSION = '0.2.0'

  class Context
    attr_reader :zmq_context

    def initialize threads = 2
      @zmq_context = ZMQ::Context.new(threads)
    end

    def socket type, *args, &block
      socket = Socket.new(zmq_context.socket(type), *args)
      block  ? block && block.call(socket) : socket
    end

    def close
      zmq_context.close
    end
  end

  class Socket
    attr_reader :zmq_socket, :type, :connection

    READABLES = [ZMQ::SUB, ZMQ::PULL, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ]
    WRITABLES = [ZMQ::PUB, ZMQ::PUSH, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ]

    def self.map_socket_option name, id
      define_method("get_#{name}") do
        zmq_socket.getsockopt(id)
      end

      define_method("set_#{name}") do |value|
        zmq_socket.setsockopt(id, value)
      end
    end

    map_socket_option :hwm,               ZMQ::HWM
    map_socket_option :swap,              ZMQ::SWAP
    map_socket_option :affinity,          ZMQ::AFFINITY
    map_socket_option :identity,          ZMQ::IDENTITY
    map_socket_option :sndbuf,            ZMQ::SNDBUF
    map_socket_option :rcvbuf,            ZMQ::RCVBUF
    map_socket_option :rate,              ZMQ::RATE
    map_socket_option :recovery_ivl,      ZMQ::RECOVERY_IVL
    map_socket_option :mcast_loop,        ZMQ::MCAST_LOOP
    map_socket_option :linger,            ZMQ::LINGER
    map_socket_option :reconnect_ivl,     ZMQ::RECONNECT_IVL
    map_socket_option :reconnect_ivl_max, ZMQ::RECONNECT_IVL_MAX
    map_socket_option :backlog,           ZMQ::BACKLOG

    def initialize zmq_socket, *args
      @zmq_socket = zmq_socket
      @fileno     = zmq_socket.getsockopt(ZMQ::FD)
      @type       = zmq_socket.getsockopt(ZMQ::TYPE)
      @closed     = false

      # default high water mark.
      set_hwm(1_000_000)
      # setup handler if one provided.
      @connection = attach(args.shift, *args) if handler?(args.first) or callback?(args.first)
    end

    def closed?
      !!@closed
    end

    def bind uri
      zmq_socket.bind(uri)
      @connection ? @connection : attach
    end

    def connect uri
      zmq_socket.connect(uri)
      @connection ? @connection : attach
    end

    def readable?
      return false if closed?
      (zmq_socket.getsockopt(ZMQ::EVENTS) & 1) == 1
    end

    def writable?
      return false if closed?
      (zmq_socket.getsockopt(ZMQ::EVENTS) & 2) == 2
    end

    def message_parts?
      return false if closed?
      zmq_socket.getsockopt(ZMQ::RCVMORE)
    end

    def send message, flags = 0
      return false if closed?
      zmq_socket.send(message, ZMQ::NOBLOCK | flags)
    end

    def recv
      return false if closed?
      zmq_socket.recv(ZMQ::NOBLOCK)
    end

    def close
      return false if closed?
      @closed = true
      zmq_socket.close
    end

    def subscribe what
      raise TypeError, 'not a ZMQ::SUB socket' if type != ZMQ::SUB
      self.tap{zmq_socket.setsockopt(ZMQ::SUBSCRIBE, what.to_s)}
    end

    def unsubscribe what
      raise TypeError, 'not a ZMQ::SUB socket' if type != ZMQ::SUB
      self.tap{zmq_socket.setsockopt(ZMQ::UNSUBSCRIBE, what.to_s)}
    end

    def attach handler = nil, *args
      @connection.detach if @connection
      @connection = set_handler(handler || EM::ZeroMQ::Connection, *args)
    end

    private

    def set_handler handler, *args
      unless handler?(handler)
        args.unshift handler
        handler = EM::ZeroMQ::CallbackConnection
      end

      EM.watch(@fileno, handler, self, *args) do |connection|
        connection.notify_readable = READABLES.include?(type)
        connection.notify_writable = WRITABLES.include?(type)
      end
    end

    def handler? object
      object.kind_of?(Class) && (object == EM::ZeroMQ::Connection || object < EM::ZeroMQ::Connection)
    end

    def callback? object
      object.respond_to?(:on_readable) && object.respond_to?(:on_writable)
    end
  end # Socket

  class Connection < EM::Connection
    attr_reader :socket

    def initialize socket, *args
      @queue, @socket  = [], socket
    end

    def send *messages
      return if messages.size < 1
      case messages.size
        when 1 then queue.push(messages.first)
        else        queue.push(messages)
      end
      self.notify_writable = true
    end

    def on_readable message
    end

    def unbind
      detach && socket.close
    end

    private

    attr_reader :queue, :on_writable

    def send_message
      return unless socket.writable?
      return self.notify_writable = false if queue.empty?

      on_writable
      case message = queue.shift
        when Array
          message[0..-2].each {|m| socket.send(m, ZMQ::SNDMORE)} if message.size > 1
          socket.send(message[-1])
        else
          socket.send(message)
      end
    end

    # NOTE: We need to read all messages, since it is edge triggered.
    def recv_message
      while socket.readable?
        messages = []
        loop do
          message   = socket.recv
          messages << message if message
          break unless socket.message_parts?
        end
        on_readable(messages) unless messages.empty?
      end
    end

    def notify_readable; recv_message end
    def notify_writable; send_message; recv_message; end # REQ-REP
  end # Connection

  class CallbackConnection < Connection
    def initialize socket, callback, *args
      @callback = callback
      super
    end

    def on_readable messages
      @callback.on_readable(self, messages)
    end

    def on_writable
      @callback.on_writable(self)
    end
  end # CallbackConnection
end # EM::ZeroMQ
