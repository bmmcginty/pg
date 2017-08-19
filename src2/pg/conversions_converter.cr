class PG::Types::Converter
def self.type
type
end
macro ttype
{{ raise "impl" }}
end
def self.pg_array
raise DB::Error.new("impl")
end
def self.from_pg(io)
raise DB::Error.new("impl")
end
def self.to_pg(io : IO, obj)
raise DB::Error.new("impl")
end
end #class

