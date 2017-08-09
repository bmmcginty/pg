class Array(T)
def self.from_pg(io : IO)
type=T
tlen=Int32.from_pg(io)
ndims=Int32.from_pg(io)
dataoffset=Int32.from_pg(io)
oid=Int32.from_pg(io)
lbounds=[] of Int32
ndims.times do
lbounds << Int32.from_pg(io)
end
if dataoffset>0
totalBits=1
dims.each do |dim|
totalBits*=dim
end
#25 items gives 4 bytes of data, 25 bits, 7 extra
readBytes=(totalBits/8)+1
readBytes+=((totalBits%8)==0) ? 0 : 1
io.skip(readBytes)
else
end #nulls? dataoffset>0?
nulls = [] of Int32
total=1
dims.each do |dim|
total=total*dim
end #each dim
t=Array(T|Nil).new
total.times do |idx|
if nulls.index(idx)
t << nil
else
t << T.from_pg io
end #if null
end #times
t
end #def
end #class

