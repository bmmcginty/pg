require "math"

class Array(T)
def self.pg_oid
T.pg_array_oid
end

def self.pg_array
raise Exception.new("multiple depth arrays are not supported")
end

def to_pg
io=IO::Memory.new
to_pg io
{format: :binary, value: io}
end

def to_pg(io)
#ndims,flags,oid,dims|lbounds,arry
1.to_pg io
nils = self.any? { |i| i==nil }
#write nil flag
(nils ? 1 : 0).to_pg io
#write type
T.pg_oid.to_pg io
#size and lbounds (which defaults to 1)
size.to_pg io
1.to_pg io
cv=PG::Types.cr_pg_converter(T)
each do |i|
startpos=io.tell
0.to_pg io
datastartpos=io.tell
case cv
when PG::Types::Converter.class
cv.to_pg io: io, obj: i
else
i.to_pg io
end
endpos=io.tell
io.seek startpos
(endpos-datastartpos).to_pg io
io.seek endpos
end #each
io.seek 0
#puts io.gets_to_end.to_slice.hexstring
end

def self.from_pg(io : IO)
ndims=Int32.from_pg(io)
if ndims > 1
raise Exception.new("Multi-dimentional arrays are not supported. gvien NDims of #{ndims}")
end
flags=Int32.from_pg(io)
oid=Int32.from_pg(io)
dims = [] of Int32
lbounds=[] of Int32
ndims.times do
dims << Int32.from_pg(io)
lb=Int32.from_pg(io)
if lb != 1
raise Exception.new("Arrays with custom lower bounds are not supported. Received #{lbounds}")
end
lbounds << lb
end
total=1
dims.each do |dim|
total=total*dim
end #each dim
t=T.pg_array.new
total.times do |idx|
size=Int32.from_pg io
if size==-1
t << nil
else
t << T.from_pg(IO::Memory.new(io.to_slice[io.tell,size]))
io.skip size
end #if
end #times
t
end #def

end #class

