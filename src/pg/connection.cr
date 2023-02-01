require "./utils"
lib LibC
fun fopen(LibC::Char*, LibC::Char*) : LibPQ::File*
end

module PG
class ConnectionError < Exception
end

class Connection < DB::Connection
  include IO::Evented

@closed = false
@connection : LibPQ::Conn
@fd : Int32

getter :fd, :connection, :closed

def check_open
raise IO::Error.new("closed connection") if @closed
end

def to_unsafe
@connection.not_nil!
end

def initialize(context)
super
@fiber=Fiber.current
cu=context.uri.dup
cu.query=nil
@connection=LibPQ.connect_start(cu.to_s)
@fd=LibPQ.socket connection
begin
connect_loop
LibPQ.setnonblocking(@connection,1_i32)
rescue e
internal_close
raise e
end
if qs=context.uri.query
if t=qs.match /trace=([^&=]+)/
tfh=LibC.fopen t[1],"wb"
LibPQ.trace @connection, tfh
end #match
end #if query
end #def

def handle_send
while 1
flushval=LibPQ.flush connection
if flushval==-1
e=String.new LibPQ.error_message(connection)
raise DB::Error.new(e)
end
break if flushval == 0
wait_readable_writable
case @read_write_event_flag
when :r, :rw
LibPQ.consume_input connection
end
next
end
end

def connect_loop
error=false
status=LibPQ::PollingStatusType::Writing
while 1
case status
when LibPQ::PollingStatusType::Writing
wait_writable
when LibPQ::PollingStatusType::Reading
wait_readable
when LibPQ::PollingStatusType::Failed
error=true
break
when LibPQ::PollingStatusType::Ok
break
end #case
status=LibPQ.connect_poll(self)
next
end #while
if error
e=String.new LibPQ.error_message(connection)
raise DB::Error.new(e)
end #if error
end #connect_loop

def resume
Crystal::Scheduler.enqueue @fiber
end

protected def do_close
super
internal_close
end

#This is separated out because a pool won't yet exist during a connect call.
#So the connection fails, we try to close the pool, and crystal segfaults.
private def internal_close
close_events
unless @closed
LibPQ.finish connection
end
@closed=true
end

def build_prepared_statement(query) : DB::Statement
#raise DB::Error.new("prepared statements not supported")
Statement.new self,query
end

def build_unprepared_statement(query) : DB::Statement
Statement.new self,query
end

def close_events
evented_close
end

end #connection class
end

