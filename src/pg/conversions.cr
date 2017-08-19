require "./conversions_converter.cr"
require "./conversions_json.cr"
require "./conversions_array.cr"
require "./types.cr"

JAN_1_2K_TICKS = Time.new(2000, 1, 1, kind: Time::Kind::Utc).ticks
ISO_8601 = "%FT%X.%L%z" 
struct Time
def to_pg(io : IO)
v=to_utc.ticks
v = v - JAN_1_2K_TICKS
v = v / Time::Span::TicksPerMillisecond
v = v * 1000
v.to_pg io
end
def self.from_pg(io)
v=Int64.from_pg(io)/1000
v = JAN_1_2K_TICKS + (Time::Span::TicksPerMillisecond*v)
t=new ticks: v, kind: Kind::Utc
t
end
end

struct Bool
def to_pg(io)
if self == true
t=1_i8
else
t=0_i8
end
t.to_pg io
end
def self.from_pg(io)
if io.read_byte==0_i8
false
else
true
end
end
end

struct Nil
def self.pg_array
Array(Nil)
end
def to_pg(io)
-1.to_pg io
end
def self.from_pg(io)
nil
end
end

{% for type in %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 Float32 Float64) %}
struct {{type.id}}
def to_pg(io : IO)
io.write_bytes(self,IO::ByteFormat::NetworkEndian)
end
def to_pg
{{ bsize =type.id.gsub(/[^0-9]/,"").to_i / 8}}
io=IO::Memory.new({{bsize}})
to_pg io
{format: :binary, value: io}
end
def self.from_pg(io : IO) : {{type.id}}
new io.read_bytes(self,IO::ByteFormat::NetworkEndian)
end
end
{% end %}

class String
def to_pg(io : IO)
io.write self.to_slice
end
def self.from_pg(io : IO) : String
s=io.to_slice[io.tell,io.size]
new s
end
end
struct Char
def self.from_pg(io)
UInt8.from_pg(io).unsafe_chr
end
def to_pg(io)
ord.to_u8.to_pg io
end
end
require "./types_catalog.cr"


