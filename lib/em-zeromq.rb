require 'zmq'
require 'eventmachine'

module EM::ZeroMQ

  VERSION = '0.1.0'

  class Context
    attr_reader :zmq_context

    def initialize threads = 2
      @zmq_context = ZMQ::Context.new(threads)
    end

    def socket type, &block
      socket = Socket.new(zmq_context.socket(type))
      block  ? block && block.call(socket) : socket
    end
  end

  class Socket
    attr_reader :zmq_socket, :type

    READABLES = [ZMQ::SUB, ZMQ::PULL, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ]
    WRITABLES = [ZMQ::PUB, ZMQ::PUSH, ZMQ::ROUTER, ZMQ::DEALER, ZMQ::REP, ZMQ::REQ]

    def self.map_socket_option name, id
      self.send(:define_method, "get_#{name}") do
        zmq_socket.getsockopt(id)
      end

      self.send(:define_method, "set_#{name}") do |value|
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

    def initialize zmq_socket
      @zmq_socket = zmq_socket
      @fileno     = zmq_socket.getsockopt(ZMQ::FD)
      @type       = zmq_socket.getsockopt(ZMQ::TYPE)

      # default to a high enough HWM
      set_hwm(1_000_000)
    end

    def bind uri, handler, *args
      attach(handler, self.tap {zmq_socket.bind(uri)}, args)
    end

    def connect uri, handler, *args
      attach(handler, self.tap {zmq_socket.connect(uri)}, args)
    end

    def readable?
      (zmq_socket.getsockopt(ZMQ::EVENTS) & 1) == 1
    end

    def writable?
      (zmq_socket.getsockopt(ZMQ::EVENTS) & 2) == 2
    end

    def message_parts?
      zmq_socket.getsockopt(ZMQ::RCVMORE)
    end

    def send message
      zmq_socket.send(message, ZMQ::NOBLOCK)
    end

    def recv
      zmq_socket.recv(ZMQ::NOBLOCK)
    end

    def close
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

    private

    def attach handler, socket, args
      EM.watch(@fileno, handler, socket, *args) do |connection|
        connection.notify_readable = READABLES.include?(type)
        connection.notify_writable = WRITABLES.include?(type)
      end
    end

  end # Socket

  class Connection < EM::Connection

    def initialize socket, *args
      @queue  = []
      @socket = socket
    end

    def send message
      queue.push(message)
      self.notify_writable = true
    end

    def on_readable message
    end

    def unbind
      detach && socket.close
    end

    private

    attr_reader :queue, :socket, :on_writable

    def send_message
      if message = queue.shift
        on_writable
        socket.send(message)
      else
        self.notify_writable = false
      end
    end

    # NOTE: We need to read all messages, since it is edge triggered.
    # TODO: At very high rates, this seems to lose notifications resulting in zmq socket going
    #       into a blocked or exceptional state - need to look into it.
    def recv_message
      while socket.readable?
        loop do
          message = socket.recv
          message && on_readable(message)
          break unless socket.message_parts?
        end
      end
    end

    def dispatch
      recv_message if socket.readable?
      send_message if socket.writable?
    end

    def notify_readable; dispatch; end
    def notify_writable; dispatch; end
  end # Connection
end # EM::ZeroMQ
