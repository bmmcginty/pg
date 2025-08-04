require "json"

module PG::Types
  # All the possible types, either base crystal types, or converters
  alias Tt = Char.class | Nil.class | Int16.class | Int32.class | Int64.class | Float32.class | Float64.class | String.class | Time.class | Bool.class | JSON::Any.class |
             Array(Char).class | Array(Nil).class | Array(Int16).class | Array(Int32).class | Array(Int64).class | Array(Float32).class | Array(Float64).class | Array(String).class | Array(Time).class | Array(Bool).class | Array(JSON::Any).class |
             Converter

  # This hash stores a mapping between pg oids and either a direct crystal class or a converter.
  # Converters can transparently adapt PG types to Crystal types and back.
  @@oids_to_crystal_classes = Hash(Int32, Tt).new

  # if we get something from the db and we want to determine the crystal type
  def self.oids_to_crystal_classes
    @@oids_to_crystal_classes
  end

  # if you want to override the to_pg and from_pg methods, call add_converter with your source type and conversion class
  macro add_converter(cls, converter)
module PG::Types
@@oids_to_crystal_classes[{{converter.id}}.pg_oid]=ConverterHolder({{converter.id}}).new
@@oids_to_crystal_classes[{{converter.id}}.pg_array_oid]=ConverterHolder(Array({{converter.id}})).new
#Array({{converter.id}}).new.as(Array(PG::Types::Converter))
#ConverterHolder(Array({{converter.id}})).new

def self.cr_pg_converter(v : {{cls.id + "|Nil"}}.class)
{{converter.id}}
end #def
def self.cr_pg_converter(v : Array({{cls.id + "|Nil"}}).class)
Array({{converter.id}})
end #def
end #module
end # macro

  # define a new built-in type
  macro type(oid, aoid, cls, name = nil, converter = nil)
@@oids_to_crystal_classes[{{oid}}]=::{{cls.id}}
@@oids_to_crystal_classes[{{aoid}}]=::Array(::{{cls.id}})

def self.cr_pg_converter(v : {{cls.id}}.class)
v
end

{% if cls.id != :Nil %}
def self.cr_pg_converter(v : ({{cls.id + "|Nil"}}).class)
{{cls.id}}
end
{% end %}

def self.cr_pg_converter(v : Array({{cls.id}}).class)
Array({{cls.id}})
end

def self.cr_pg_converter(v : Array({{cls.id}}|Nil).class)
Array({{cls.id}})
end

{% if cls.resolve < Value %}
struct ::{{cls.id}}
#{% unless cls.resolve < ::PG::Types::Converter %}
def self.pg_array
Array({{cls.id}}|Nil)
end
#{% end %}
def self.pg_oid
{{oid}}
end
def self.pg_array_oid
{{aoid}}
end
def to_pg
io=IO::Memory.new
to_pg io
{ format: :binary, value: io }
end
end
{% else %}
class ::{{cls.id}}
#{% unless cls.resolve < ::PG::Types::Converter %}
def self.pg_array
Array({{cls.id}}|Nil)
end
#{% end %}
def self.pg_oid
{{oid}}
end
def self.pg_array_oid
{{aoid}}
end
def to_pg
io=IO::Memory.new
to_pg io
{ format: :binary, value: io }
end
end
{% end %}
end # macro

end
