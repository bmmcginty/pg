require "./utils"
lib LibC
fun fopen(LibC::Char*, LibC::Char*) : LibPQ::File*
end

module PG
class ConnectionError < Exception
end

class Connection < DB::Connection
include ::PG::IOUtils
@closed = false
@connection : LibPQ::Conn
@fiber : Fiber
@flags = ""

getter! :connection,:flags,:fiber,:closed
setter :flags

def to_unsafe
@connection.not_nil!
#.as(LibPQ::Conn)
end

def initialize(context)
super
@fiber=Fiber.current
cu=context.uri.dup
cu.query=nil
@connection=LibPQ.connect_start(cu.to_s)
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
fd=LibPQ.socket connection
#puts "handle send"
while 1
flushval=LibPQ.flush connection
#puts "flush #{flushval}"
#~~
if flushval==-1
e=String.new LibPQ.error_message(connection)
raise DB::Error.new(e)
end
break if flushval == 0
create_event_rw fd
Scheduler.reschedule
if flags.index("r")
LibPQ.consume_input connection
end
next
end
#puts "end do_send"
end

def connect_loop
fd=LibPQ.socket connection
error=false
status=LibPQ::PollingStatusType::Writing
while 1
case status
when LibPQ::PollingStatusType::Writing
e=create_event_w fd
when LibPQ::PollingStatusType::Reading
e=create_event_r fd
when LibPQ::PollingStatusType::Failed
error=true
break
when LibPQ::PollingStatusType::Ok
break
end #case
Scheduler.reschedule
status=LibPQ.connect_poll(self)
next
end #while
if error
e=String.new LibPQ.error_message(connection)
raise DB::Error.new(e)
end #if error
end #connect_loop

def resume
@fiber.resume
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

def build_prepared_statement(query)
#raise DB::Error.new("prepared statements not supported")
Statement.new self,query
end

def build_unprepared_statement(query)
Statement.new self,query
end

end #connection class
end

