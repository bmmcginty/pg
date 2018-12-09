class PG::Types::JSONBConverter < PG::Types::Converter
def self.pg_oid
3802
end
def self.pg_array_oid
3807
end
def self.pg_array
Array(JSON::Any|Nil)
end
def self.from_pg(io : IO)
v=io.read_byte
#io.gets_to_end
JSON.parse io
end
def self.to_pg(io : IO, obj)
io.write_byte 1_u8
io.write obj.to_json.to_slice
end
end

class PG::Types::JSONConverter < PG::Types::Converter
def self.pg_oid
114
end
def self.pg_array_oid
199
end
def self.pg_array
Array(JSON::Any|Nil)
end
def self.from_pg(io)
JSON.parse io
end
def self.to_pg(io : IO, obj : JSON::Any)
io << obj.to_json
end
end

