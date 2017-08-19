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
@closed=false


setter :flags
getter :col_num,:row_num
getter! :connection,:affected_rows

def initialize(@statement,@query)
super statement
@fiber=Fiber.current
@connection=statement.connection
puts "rs created for #{@query}"
#puts "getting tuple in init"
@tuple=get_tuple.not_nil!
#puts "got tuple:#{@tuple}"
handle_error
#get_affected_rows
end

def get_affected_rows
return @affected_rows.not_nil! if @affected_rows
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

def get_io
@col_num+=1
if LibPQ.getisnull(row,row_num,col_num-1)==1
return nil
end
size=LibPQ.getlength(row,row_num,col_num-1)
value=LibPQ.getvalue(row,row_num,col_num-1)
#ptr=Pointer.malloc(size) { |i| value[i] }
IO::Memory.new(value.to_slice(size),writeable: false)
end

def st
LibPQ.result_status(@tuple.not_nil!).to_s
end

def stc
String.new LibPQ.cmd_status(@tuple.not_nil!)
end

#get the type of the value coming from pg
#if that value has a converter, use that converter
#if you want to avoid using a converter, use read_without_converter
def read
typ=LibPQ.ftype(row,col_num)
t=Types.oids_to_crystal_classes[typ]?
#puts "typ:#{typ},t:#{t}"
#get_class(typ.to_i32)
unless t
e="pg type #{typ} not supported"
puts e
close
raise DB::Error.new(e)
end
#get crystal class from pgoid
case t
when PG::Types::Converter
#get the converter from the converter pointer
#and send it to read
read t.class.type
else
#otherwise just send the class to read
read t
end
end

def read!(type)
read(type).not_nil!
end

#gets the tyep converter
#and reads via the converter
def read(type)
desttype=PG::Types.cr_pg_converter(type)
#puts "tyep:#{type},desttype:#{desttype}"
read_without_converter desttype
end

#whatever class is supplied here is used to read the pg value and return it as a cr type
def read_without_converter(type)
io=get_io
unless io
return nil
end
type.from_pg io.not_nil!
end

protected def do_close
return if @closed
puts "close"
while move_next
end
LibPQ.clear @tuple.not_nil!
@tuple=nil
close_events
super
@closed=true
end

def move_next
if @eof == true
return false
end
error=nil
ret=false
while 1
if row_num < (row_count-1) && row_count > 0
@row_num+=1
@col_num=0
ret=true
break
end
t=get_tuple
if t == nil
@eof=true
ret=false
break
end
LibPQ.clear row
@tuple=t.not_nil!
@row_num=-1
end
handle_error
ret
end

def handle_error
#puts self.st,self.stc
st=LibPQ.result_status(row)
#puts "st:#{st}"
case st
when .bad_response?
when .fatal_error?
e=String.new(LibPQ.error_message(connection))
puts e
close
raise DB::Error.new(e)
end
end

def resume
@fiber.resume
end

def get_tuple
while 1
good=LibPQ.consume_input(@connection)
if good==0
#puts "good:0"
e=String.new LibPQ.error_message(connection)
puts e
close
raise DB::Error.new(e)
end
#handle_notifications
busy=LibPQ.is_busy(@connection)
if busy==0
ret=LibPQ.get_result(@connection)
wtf = "ret:#{ret}, query:#{@query}"
if ret
wtf += ", status:#{LibPQ.result_status(ret)}"
else
wtf += ", status: null"
end
puts wtf
return ret
end
create_event_r LibPQ.socket(@connection)
Scheduler.reschedule
end #while
end #def
end #class

end #module
