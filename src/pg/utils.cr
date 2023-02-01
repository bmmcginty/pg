# optomized for connection and result-set in pq
# so we timeout using the write_timeout if set
# because we won't typically read anything when doing the connect/flush dance
module IO::Evented
  @read_write_event_flag = :nil
  @readers_writers = Crystal::ThreadLocalValue(Deque(Fiber)).new
  @read_write_event = Crystal::ThreadLocalValue(Crystal::EventLoop::Event).new

  # :nodoc:
  def resume_read_write(event=:nil, timed_out = false) : Nil
	@read_write_event_flag = event
    @write_timed_out = timed_out

    if reader_writer = @readers_writers.get?.try &.shift?
      Crystal::Scheduler.enqueue reader_writer
    end
  end

  # :nodoc:
  def wait_readable_writable(timeout = @write_timeout) : Nil
    wait_readable_writable(timeout: timeout) { raise TimeoutError.new("Read/write timed out") }
  end

  # :nodoc:
  def wait_readable_writable(timeout = @write_timeout, *, raise_if_closed = true) : Nil
    readers_writers = @readers_writers.get { Deque(Fiber).new }
    readers_writers << Fiber.current
    add_read_write_event(timeout)
    Crystal::Scheduler.reschedule

    if @write_timed_out
      @write_timed_out = false
      yield
    end

    check_open if raise_if_closed
  end

  private def add_read_write_event(timeout = @write_timeout) : Nil
    event = @read_write_event.get { Crystal::Scheduler.event_loop.create_fd_read_write_event(self) }
    event.add timeout
  end

  def evented_close : Nil
    @read_event.consume_each &.free

    @write_event.consume_each &.free

    @read_write_event.consume_each &.free

    @readers.consume_each do |readers|
      Crystal::Scheduler.enqueue readers
    end

    @writers.consume_each do |writers|
      Crystal::Scheduler.enqueue writers
    end

    @readers_writers.consume_each do |readers_writers|
      Crystal::Scheduler.enqueue readers_writers
    end

  end

end

class Crystal::LibEvent::EventLoop < Crystal::EventLoop
  # Creates a read|write event for a file descriptor.
  def create_fd_read_write_event(io : IO::Evented, edge_triggered : Bool = false) : Crystal::EventLoop::Event
    flags = LibEvent2::EventFlags::Read
    flags |= LibEvent2::EventFlags::Write
    flags |= LibEvent2::EventFlags::Persist | LibEvent2::EventFlags::ET if edge_triggered

    event_base.new_event(io.fd, flags, io) do |s, flags, data|
      io_ref = data.as(typeof(io))
      if flags.includes?(LibEvent2::EventFlags::Read&LibEvent2::EventFlags::Write)
        io_ref.resume_read_write(event: :rw)
      elsif flags.includes?(LibEvent2::EventFlags::Read)
        io_ref.resume_read_write(event: :r)
      elsif flags.includes?(LibEvent2::EventFlags::Write)
        io_ref.resume_read_write(event: :w)
      elsif flags.includes?(LibEvent2::EventFlags::Timeout)
        io_ref.resume_read_write(timed_out: true)
      end
    end
  end
end


