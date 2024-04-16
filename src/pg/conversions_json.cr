struct JSON::Any
def self.from_pg(io : IO)
v=io.read_byte
JSON.parse io
end
def to_pg(io : IO)
io.write_byte 1_u8
io.write self.to_json.to_slice
end
end
