lib LibC
  fun fopen(LibC::Char*, LibC::Char*) : LibPQ::File*
end

class PG::ConnectionError < Exception
end

class PG::Connection < DB::Connection
  @closed = false
  @connection : LibPQ::Conn
  @io : IO::FileDescriptor
  @read_timeout : Time::Span? = nil
  @write_timeout : Time::Span? = nil

  getter :io, :connection, :closed

  def check_open
    raise IO::Error.new("closed connection") if @closed
  end

  def to_unsafe
    @connection.not_nil!
  end

  def initialize(context)
    super
    @fiber = Fiber.current
    cu = context.uri.dup
    cu.query = nil
    @connection = LibPQ.connect_start(cu.to_s)
    socket = LibPQ.socket(connection)
    IO::FileDescriptor.set_blocking(socket, false)
    @io = IO::FileDescriptor.new(handle: socket)
    begin
      connect_loop
      LibPQ.setnonblocking(@connection, 1_i32)
    rescue e
      internal_close
      raise e
    end
    if qs = context.uri.query
      if t = qs.match /trace=([^&=]+)/
        tfh = LibC.fopen t[1], "wb"
        LibPQ.trace @connection, tfh
      end # match
    end   # if query
  end     # def

  def handle_send
    while 1
      flushval = LibPQ.flush connection
      case flushval
      when -1
        e = String.new LibPQ.error_message(connection)
        raise DB::Error.new(e)
      when 0
        break
      end

      Crystal::EventLoop.current.wait_readable_or_writable(@io)
      if LibPQ.consume_input(connection) == 0
        e = String.new LibPQ.error_message(connection)
        raise DB::Error.new(e)
      end
      # If the socket was write-ready, the next loop iteration calls PQflush.
      # If it was read-ready, draining input can unblock the server.
    end
  end

  def connect_loop
    error = false
    tmp_status = status = LibPQ::PollingStatusType::Writing
    while 1
      case status
      when .writing?
        if status != tmp_status
          Crystal::EventLoop.current.wait_writable(@io)
          tmp_status = status
        end
      when .reading?
        if status != tmp_status
          Crystal::EventLoop.current.wait_readable(@io)
          tmp_status = status
        end
      when .failed?
        error = true
        break
      when .ok?
        break
      end # case
      status = LibPQ.connect_poll(self)
      next
    end # while
    if error
      e = String.new LibPQ.error_message(connection)
      raise DB::Error.new(e)
    end # if error
  end   # connect_loop

  protected def do_close
    super
    internal_close
  end

  # This is separated out because a pool won't yet exist during a connect call.
  # So the connection fails, we try to close the pool, and crystal segfaults.
  private def internal_close
    @io.close
    unless @closed
      LibPQ.finish connection
    end
    @closed = true
  end

  def build_prepared_statement(query) : DB::Statement
    Statement.new self, query
  end

  def build_unprepared_statement(query) : DB::Statement
    Statement.new self, query
  end
end # connection class
