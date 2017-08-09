module PG
class Statement < DB::Statement
@query: String
def initialize(@connection,@query)
super @connection
end

protected def perform_exec(args : Enumerable) : DB::ExecResult
pq=perform_query(args)
pq.do_close
ar=pq.affected_rows
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
converter=Types.get_converter?(i.class)
if converter
conv=converter.to_pg(i)
else
conv=i.to_pg
end
paramTypes << Types.get_oid(i.class).to_u32
paramFormats << ((conv[:format]==:text) ? 0_i32 : 1_i32)
paramLengths << conv[:value].as(IO::Memory).size
pv=conv[:value].as(IO::Memory)
paramValues[idx]=pv.to_slice.pointer 0
# << pointerof(pv)
end
resultFormat=1 #binary
LibPQ.send_query_params(connection,@query,args.size,paramTypes,paramValues,paramLengths,paramFormats,resultFormat)
LibPQ.set_single_row_mode connection
ResultSet.new self,@query
end #perform_query

end
end

