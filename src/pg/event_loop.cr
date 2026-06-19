lib LibC
  {% unless LibC.has_constant?(:POLLIN) %}
    POLLIN  =  1
    POLLOUT =  4
    POLLERR =  8
    POLLHUP = 16
  {% end %}

  {% unless LibC.has_constant?(:Pollfd) %}
    struct Pollfd
      fd : Int
      events : Short
      revents : Short
    end
  {% end %}

  fun poll(fds : Pollfd*, nfds : ULong, timeout : Int) : Int
end

abstract class Crystal::EventLoop
  # Waits until *file_descriptor* can make read or write progress.
  #
  # This is the readiness primitive libpq needs when PQflush still has buffered
  # output: either writable socket space or readable server input can unblock it.
  def wait_readable_or_writable(file_descriptor : Crystal::System::FileDescriptor) : Nil
    pollfd = LibC::Pollfd.new
    pollfd.fd = file_descriptor.fd
    pollfd.events = (LibC::POLLIN | LibC::POLLOUT).to_i16

    loop do
      ret, errno = Fiber.syscall do
        ret = LibC.poll(pointerof(pollfd), 1_u64, -1)
        {ret, Errno.value}
      end

      if ret == -1
        next if errno == Errno::EINTR
        raise IO::Error.from_os_error("poll", errno, target: file_descriptor)
      end

      return
    end
  end
end

{% if flag?(:unix) && (flag?("evloop") == "epoll" || flag?("evloop") == "kqueue" || (!flag?("evloop") && (flag?(:android) || flag?(:linux) || flag?(:darwin) || flag?(:freebsd)))) %}
  struct Crystal::EventLoop::Polling::PollDescriptor
    @readers_or_writers = Crystal::EventLoop::Polling::Waiters.new

    def empty? : Bool
      @readers.@list.empty? && @writers.@list.empty? && @readers_or_writers.@list.empty?
    end
  end

  abstract class Crystal::EventLoop::Polling < Crystal::EventLoop
    def wait_readable_or_writable(file_descriptor : Crystal::System::FileDescriptor) : Nil
      wait_readable_or_writable(file_descriptor) do
        raise IO::TimeoutError.new("Read/write timed out")
      end
    end

    private def wait_readable_or_writable(io, &) : Nil
      yield if wait(:io_read, io, nil) do |pd, event|
                 return unless pd.value.@readers_or_writers.add(event)
               end
    end
  end

  {% if flag?("evloop") == "epoll" || (!flag?("evloop") && (flag?(:android) || flag?(:linux))) %}
    class Crystal::EventLoop::Epoll < Crystal::EventLoop::Polling
      private def process_io(epoll_event : LibC::EpollEvent*, &) : Nil
        index = Polling::Arena::Index.new(epoll_event.value.data.u64)
        events = epoll_event.value.events

        Crystal.trace :evloop, "event", fd: index.index, index: index.to_i64, events: events

        Polling.arena.get?(index) do |pd|
          if (events & (LibC::EPOLLERR | LibC::EPOLLHUP)) != 0
            pd.value.@readers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@readers_or_writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            return
          end

          if (events & LibC::EPOLLRDHUP) == LibC::EPOLLRDHUP
            pd.value.@readers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@readers_or_writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
          elsif (events & LibC::EPOLLIN) == LibC::EPOLLIN
            pd.value.@readers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@readers_or_writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
          end

          if (events & LibC::EPOLLOUT) == LibC::EPOLLOUT
            pd.value.@writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@readers_or_writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
          end
        end
      end
    end
  {% elsif flag?("evloop") == "kqueue" || (!flag?("evloop") && (flag?(:darwin) || flag?(:freebsd))) %}
    class Crystal::EventLoop::Kqueue < Crystal::EventLoop::Polling
      private def process_io(kevent : LibC::Kevent*, &) : Nil
        index =
          {% if flag?(:bits64) %}
            Polling::Arena::Index.new(kevent.value.udata.address)
          {% else %}
            Polling::Arena::Index.new(kevent.value.ident.to_i32!, kevent.value.udata.address.to_u32!)
          {% end %}

        Crystal.trace :evloop, "event", fd: kevent.value.ident, index: index.to_i64,
          filter: kevent.value.filter, flags: kevent.value.flags, fflags: kevent.value.fflags

        Polling.arena.get?(index) do |pd|
          if (kevent.value.fflags & LibC::EV_EOF) == LibC::EV_EOF
            pd.value.@readers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            pd.value.@readers_or_writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            return
          end

          case kevent.value.filter
          when LibC::EVFILT_READ
            if (kevent.value.fflags & LibC::EV_ERROR) == LibC::EV_ERROR
              pd.value.@readers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
              pd.value.@readers_or_writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            else
              pd.value.@readers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
              pd.value.@readers_or_writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            end
          when LibC::EVFILT_WRITE
            if (kevent.value.fflags & LibC::EV_ERROR) == LibC::EV_ERROR
              pd.value.@writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
              pd.value.@readers_or_writers.ready_all { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            else
              pd.value.@writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
              pd.value.@readers_or_writers.ready_one { |event| unsafe_resume_io(event) { |fiber| yield fiber } }
            end
          end
        end
      end
    end
  {% end %}
{% elsif flag?(:unix) && flag?("evloop") == "io_uring" %}
  class Crystal::EventLoop::IoUring < Crystal::EventLoop
    def wait_readable_or_writable(file_descriptor : Crystal::System::FileDescriptor) : Nil
      async_poll(file_descriptor, LibC::POLLIN | LibC::POLLOUT | LibC::POLLRDHUP, nil) do
        "Read/write timed out"
      end
    end
  end
{% elsif flag?(:unix) && (flag?("evloop") == "libevent" || (!flag?("evloop") && !(flag?(:android) || flag?(:linux) || flag?(:darwin) || flag?(:freebsd)))) %}
  class Crystal::EventLoop::LibEvent < Crystal::EventLoop
    def wait_readable_or_writable(file_descriptor : Crystal::System::FileDescriptor) : Nil
      event = event_base.new_event(
        file_descriptor.fd,
        LibEvent2::EventFlags::Read | LibEvent2::EventFlags::Write,
        Fiber.current
      ) do |s, flags, data|
        f = data.as(Fiber)
        {% if flag?(:execution_context) %}
          event_loop = Crystal::EventLoop.current.as(Crystal::EventLoop::LibEvent)
          event_loop.callback_enqueue(f)
        {% else %}
          f.enqueue
        {% end %}
      end

      event.add(nil)
      Fiber.suspend
      raise IO::Error.new("Closed stream") if file_descriptor.closed?
    ensure
      event.try(&.free)
    end
  end
{% end %}
