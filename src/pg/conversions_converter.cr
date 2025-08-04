class PG::Types::Converter
  def type
    raise DB::Error.new("converter#type not impl")
  end

  def self.pg_array
    raise DB::Error.new("converter.pg_array not impl")
  end

  def self.from_pg(io)
    raise DB::Error.new("converter.from_pg(io) impl")
  end

  def self.to_pg(obj)
    io = IO::Memory.new
    to_pg io: io, obj: obj
    {format: :binary, value: io}
  end

  def self.to_pg(io : IO, obj)
    raise DB::Error.new("converter.to_pg(io,obj) not impl")
  end

  def self.pg_oid
    raise DB::Error.new("Converter.pg_oid not impl")
  end

  def self.pg_array_oid
    raise DB::Error.new("Converter.pg_array_oid not impl")
  end
end # class

class PG::Types::ConverterHolder(T) < PG::Types::Converter
  def type
    T
  end
end
