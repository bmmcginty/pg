require "./conversions_converter.cr"
require "./conversions_json.cr"
require "./conversions_array.cr"
require "./types.cr"

class Object
def to_pg
raise Exception.new("to_pg for #{self} not impl")
end
end

#JAN_1_2K_TICKS = Time.new(2000, 1, 1, kind: Time::Kind::Utc).ticks
PG_EPOCH=Time.utc(2000,1,1,0,0,0).epoch_microseconds
ISO_8601 = "%FT%X.%L%z" 
struct Time
MICROSECONDS_PER_SECOND = 1_000_000_i64

def microsecond
nanosecond / NANOSECONDS_PER_MICROSECOND
end

def epoch_microseconds : Int64
epoch * MICROSECONDS_PER_SECOND + microsecond
end

def self.epoch_microseconds(microseconds : Int) : Time
seconds=UNIX_SECONDS + (microseconds / MICROSECONDS_PER_SECOND)
nanoseconds = (microseconds % MICROSECONDS_PER_SECOND) * NANOSECONDS_PER_MICROSECOND
utc(seconds: seconds, nanoseconds: nanoseconds.to_i)
end

#puts Time.epoch_microseconds(PG_EPOCH)
def to_pg(io : IO)
v=to_utc.epoch_microseconds
v = v - PG_EPOCH
v.to_pg io
end

def self.from_pg(io)
v=Int64.from_pg(io)
Time.epoch_microseconds(v+PG_EPOCH)
end

end

struct Bool
def to_pg(io)
t = self ? 1_i8 : 0_i8
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
io
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


