require "./utils"
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
LibPQ.setnonblocking(@connection,1)
rescue e
do_close
raise e
end
end

def handle_send
fd=LibPQ.socket connection
while 1
flushval=LibPQ.flush connection
break if flushval == 0
create_event_rw fd
Scheduler.reschedule
if flags.index("r")
LibPQ.consume_input connection
end
next
end

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
#puts "first_connect,#{e}"
Scheduler.reschedule
status=LibPQ.connect_poll(self)
#puts "status:#{status}"
next
end #while
if error
raise DB::Error.new("error")
end #if error
end #connect_loop

def resume
@fiber.resume
end

protected def do_close
super
close_events
LibPQ.finish connection unless @closed
@closed=true
end

def build_prepared_statement(query)
#raise DB::Error.new("prepared statements not supported")
Statement.new self,query
end

def build_unprepared_statement(query)
##puts "new statement"
Statement.new self,query
end

end #connection class
end

