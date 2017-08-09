require "../conversions"
class Array(T)
def self.from_pg(io : IO)
self.from_pg_a(io)
end
def self.from_pg_a(io : IO)
tlen=Int32.from_pg(io)
ndims=Int32.from_pg(io)
dataoffset=Int32.from_pg(io)
oid=Int32.from_pg(io)
type=PG::Types.get_class(oid)
dims=Array(Int32).new(ndims)
ndims.times do
dims << Int32.from_pg(io)
end
lbounds=Array(Int32).new(ndims)
ndims.times do
lbounds << Int32.from_pg(io)
end
nulls=[] of Int32
if dataoffset > 0
total_bits=1
dims.each do |dim|
total_bits=total_bits*dim
end #dims
get_nulls(nulls,io,total_bits)
extra=(total_bits/8)%4
while extra > 0
io.read_byte
extra-=1
end #while extra
end #nulls
make_array dims,nulls,io
end

alias At=Array(T|Nil|At)
def self.make_array(dims,nulls,io)
if dims.size==0
return Array(At).new
end
if dims.size == 1
t=Array(T?).new
dims[0].times do |where|
if nulls.index(where)
t << nil
else
t << T.from_pg(io)
end
end
return t
end
itemArrayCount=1
dims[0..-2].each do |t|
itemArrayCount=itemArrayCount*t
end
itemArrays=Array(At).new(itemArrayCount)
ctr=-1
itemArrayCount.times do |idx|
ia=Array(T?).new(dims[-1])
itemArrays << ia.as(At)
dims[-1].times do
ctr+=1
if nulls.index(ctr)
b=nil
else
b=T.from_pg(io)
end #nil or T
ia << b
end #last_dim count
end #itemArrays
t=Array(At).new
recarray t,dims[0..-1] do |fa|
fa << itemArrays.shift
end #fa
end

def self.recarray(dest,dims)
unless dims.size > 0
yield dest
end
dims.each do |dim|
t << Array(At).new
dim.times do |i|
recarray t[-1],dims[1..-1]
end
end
end

def self.get_nulls(nulls,io,total_bits)
ctr=0
pos=-1
mult=255_u8
while 1
break if ctr >= total_bits
if mult>128_u8
mult=1_u8
bit=io.read_byte
end #if
if bit.not_nil!&mult > 0
nulls << ctr
end #if
ctr+=1
mult=mult*2_u8
end #while
end

end

s="00000002000000010000001700000004000000010000000300000001ffffffff000000040000000200000004000000030000000400000004ffffffff000000040000000600000004000000070000000400000008ffffffffffffffff000000040000000b000000040000000c"
io=IO::Memory.new
4.times do
io.write_byte 0_u8
end
a=0
nums=['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
pos=0
((s.size.not_nil!)/2).times do
c1=UInt8.new nums.index(s[pos]).not_nil!
c2=UInt8.new nums.index(s[pos+1]).not_nil!
t=0_u8
t+=(c1*16_u8)+c2
io.write_byte t
pos+=2
end
Array(UInt8).from_pg(io)
