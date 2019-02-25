module PG
class ResultSet < DB::ResultSet
include ::PG::IOUtils
@query : String?
@statement : DB::Statement
@connection : DB::Connection
@fiber : Fiber
@tuple : LibPQ::Result?
@row_num=-1
@col_num=0
@affected_rows : Int64?
@flags=""
@eof=false

setter :flags
getter :col_num,:row_num
getter! :connection,:affected_rows

def initialize(@statement,@query)
super statement
@fiber=Fiber.current
@connection=statement.connection
#puts "a:#{@query}"
@tuple=get_tuple.not_nil!
#puts "b:#{@query}"
get_affected_rows
end

def get_affected_rows
if @affected_rows
@affected_rows
else
p=LibPQ.cmd_tuples(row)
s=String.new(p)
if s==""
t=0_i64
else
t=s.to_i64
end
@affected_rows=t
t
end
end

def row
@tuple.not_nil!
end

def row_count
LibPQ.ntuples(row)
end

def column_count
LibPQ.nfields(row)
end

def column_name(index : Int) : String
String.new LibPQ.fname(row,index).dup
end

def column_names
size=column_count
t=Array(String).new(size)
size.times do |idx|
t << column_name(idx)
end
t
end

def [](key)
@col_num=0
@col_num=column_names.index(key).not_nil!
read
end

def get_io
#puts "get_io:#{row_num},tuple:#{@tuple},col:#{col_num},st:#{st},stc:#{stc}"
@col_num+=1
if LibPQ.getisnull(row,row_num,col_num-1)==1
return nil
end
size=LibPQ.getlength(row,row_num,col_num-1)
value=LibPQ.getvalue(row,row_num,col_num-1)
IO::Memory.new(value.to_slice(size),writeable: false)
end

def st
LibPQ.result_status(@tuple.not_nil!).to_s
end

def stc
String.new LibPQ.cmd_status(@tuple.not_nil!)
end

def read
typ=LibPQ.ftype(row,col_num)
begin
t=Types.oids_to_crystal_classes[typ]
rescue e
raise DB::Error.new("pg type #{typ} not supported")
end
case t
when PG::Types::Converter
read_without_converter t.type
else
read_without_converter t
end
end

def read_without_converter(type)
io=get_io
return nil unless io
#puts "type #{type} io #{io}"
type.from_pg io.not_nil!
end

def read(type)
t=PG::Types.cr_pg_converter(type)
read_without_converter t
end

protected def do_close
super
while move_next
end
LibPQ.clear @tuple.not_nil!
@tuple=nil
close_events
end

def move_next
#puts "move_next row_num:#{row_num},row_count:#{row_count},tuple:#{@tuple},status:#{st},stc:#{stc}"
begin
t=mmove_next
#puts "move_next got:#{t}"
#puts "move_next:#{t}"
return t
rescue e
#puts "move_next got:#{e}"
#puts "move_next:#{e}"
raise e
end
end

def mmove_next
if @eof == true
#puts "move_next:eof=true"
return false
end
error=nil
ret=false
while 1
#puts "row_num:#{row_num},row_count:#{row_count},tuple:#{@tuple},status:#{st},cst:#{cst}"
if row_num < (row_count-1) && row_count > 0
@row_num+=1
@col_num=0
ret=true
break
end
t=get_tuple
#puts "tuple:#{t}"
if t == nil
@eof=true
ret=false
break
end
LibPQ.clear row
@tuple=t.not_nil!
@row_num=-1
#puts "continuing while"
end
handle_error
ret
end

def handle_error
st=LibPQ.result_status(row)
case st
when .bad_response?
when .fatal_error?
e=String.new(LibPQ.error_message(connection))
raise DB::Error.new(e)
end
end

def resume
@fiber.resume
end

def get_tuple
while 1
good=LibPQ.consume_input(@connection)
#puts "good:#{good}"
if good==0
e=String.new LibPQ.error_message(connection)
#puts "e:#{e}"
#puts "eek! #{e}"
raise DB::Error.new(e)
end
#handle_notifications
busy=LibPQ.is_busy(@connection)
#puts "busy:#{busy}"
if busy==0
ret=LibPQ.get_result(@connection)
#puts "ret:#{ret}"
return ret
end
create_event_r LibPQ.socket(@connection)
#puts "rescheduling"
Crystal::Scheduler.reschedule
end #while
end #def
end #class

end #module
