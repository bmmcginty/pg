require "./conversions_array.cr"
require "./types.cr"
class PG::Types::JSONB < PG::Types::Converter
def self.from_pg(io)
v=io.read_byte
JSON.parse(io)
end
def self.to_pg(obj)
io=IO::Memory.new
io.write_byte 1_u8
io.write obj.to_json.to_slice
{format: :binary, value: io}
end
end

struct JSON::Any
def self.from_pg(io : IO::Memory)
JSON.parse(io)
end
def to_pg
{format: :binary,value: IO::Memory.new(self.to_json) }
end
end

JAN_1_2K_TICKS = Time.new(2000, 1, 1, kind: Time::Kind::Utc).ticks
ISO_8601 = "%FT%X.%L%z" 
struct Time
def to_pg
{format: :text, value: to_s(ISO_8601).to_slice}
end
def self.from_pg(io)
v=Int64.from_pg(io)/1000
new JAN_1_2K_TICKS+(Time::Span::TicksPerMillisecond*v), kind: Kind::Utc
end
end

struct Bool
def to_pg
if self == true
t="\x01"
else
t="\x00"
end
{format: :text, value: IO::Memory.new(t)}
end
def self.from_pg(io)
if io.read_byte==1
true
else
false
end
end
end

struct Nil
def to_pg
{format: :text, value: IO::Memory.new("")}
end
def self.from_pg(io)
nil
end
end

{% for type in %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 Float32 Float64) %}
struct {{type.id}}
def to_pg
{{ bsize =type.id.gsub(/[^0-9]/,"").to_i / 8}}
io=IO::Memory.new({{bsize}})
io.write_bytes(self,IO::ByteFormat::NetworkEndian)
{format: :binary, value: io}
end
def self.from_pg(io : IO) : {{type.id}}
new io.read_bytes(self,IO::ByteFormat::NetworkEndian)
end
end
{% end %}

class String
def to_pg
{format: :binary, value: IO::Memory.new(self)}
end
def self.from_pg(io : IO) : String
t=Bytes.new(io.size)
io.read_fully(t)
new t
end
end


