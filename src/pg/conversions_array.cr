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
#puts "to_pg,#{T}"
#ndims,flags,oid,dims|lbounds,arry
1.to_pg io
nils = self.any? { |i| i==nil }
#write nil flag
(nils ? 1 : 0).to_pg io
cv=PG::Types.cr_pg_converter(T)
#write type
cv.pg_oid.to_pg io
#size and lbounds (which defaults to 1)
size.to_pg io
1.to_pg io
each do |i|
startpos=io.tell
if i==nil
-1.to_pg io
else
0.to_pg io
datastartpos=io.tell
do_convert(cv,io,i)
endpos=io.tell
io.seek startpos
(endpos-datastartpos).to_pg io
io.seek endpos
end #not nil
end #each
io.seek 0
#puts io.gets_to_end.to_slice.hexstring
end

def do_convert(cv : PG::Types::Converter.class, io, i)
cv.to_pg io: io, obj: i
end
def do_convert(cv,io,i)
i.to_pg io
end

def self.from_pg(io : IO)
ndims=Int32.from_pg(io)
if ndims > 1
raise Exception.new("Multi-dimentional arrays are not supported. gvien NDims of #{ndims}")
end
t=T.pg_array.new
if ndims==0
return t
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

