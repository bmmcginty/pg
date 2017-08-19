module PG
class Statement < DB::Statement
@query: String
def initialize(@connection,@query)
super @connection
end

protected def perform_exec(args : Enumerable) : DB::ExecResult
rs = perform_query(args)
ar = rs.get_affected_rows
::DB::ExecResult.new(
rows_affected: ar,
last_insert_id: 0_i64
)
end

protected def perform_query(args : Enumerable) : DB::ResultSet
paramTypes=Array(UInt32).new(args.size)
paramFormats=Array(Int32).new(args.size)
paramValues=Pointer(Pointer(UInt8)).malloc(args.size)
paramLengths=Array(Int32).new(args.size)
args.each_with_index do |i,idx|
next if i.is_a?(Slice(UInt8))
data,oid=do_convert(i,i.class)
paramTypes << oid.to_u32
paramFormats << ((data[:format]==:text) ? 0_i32 : 1_i32)
paramLengths << data[:value].as(IO::Memory).size
pv=data[:value].as(IO::Memory)
paramValues[idx]=pv.to_slice.pointer 0
# << pointerof(pv)
end
resultFormat=1 #binary
st=LibPQ.send_query_params(connection,@query,args.size,paramTypes,paramValues,paramLengths,paramFormats,resultFormat)
if st==0
raise DB::Error.new(String.new(LibPQ.error_message(connection)))
end
puts "send_query_params:#{st}, query:#{@query}"
LibPQ.set_single_row_mode connection
t=ResultSet.new self,@query
t
end #perform_query

#take an instance and a class,
#get the converter,
#run the converter over the instance,
#convert it to pg,
#and return {conversion,oid}
def do_convert(instance,instanceClass)
converter=Types.cr_pg_converter(instanceClass)
#puts "instance:#{instance},instanceClass:#{instanceClass},converter:#{converter}"
do_convert2(instance,converter)
end

def do_convert2(instance, converter : PG::Types::Converter.class)
{converter.to_pg(instance),converter.pg_oid}
end

#converter will be the class of the item here, which is why we pass instance in as well
def do_convert2(instance,converter)
{instance.to_pg,converter.pg_oid}
end

end #class
end #module

