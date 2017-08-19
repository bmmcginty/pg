require "json"

module PG
module Types
class Converter
def self.pg_array
raise DB::Error.new("impl")
end
def self.from_pg(io)
raise DB::Error.new("impl")
end
def self.to_pg(obj)
raise DB::Error.new("impl")
end
end

#we support jsonb out of the box

alias Tt=\
Nil.class|Int16.class|Int32.class|Int64.class|Float32.class|Float64.class|String.class|Time.class|Bool.class|JSON::Any.class|\
Array(Nil).class|Array(Int16).class|Array(Int32).class|Array(Int64).class|Array(Float32).class|Array(Float64).class|Array(String).class|Array(Time).class|Array(Bool).class|Array(JSON::Any).class|\
::PG::Types::JSONB.class|::Array(::PG::Types::JSONB).class|\
Converter.class|Array(Converter).class

@@oids_to_crystal_classes=Hash(Int32,Tt).new

#if you want to override the to_pg and from_pg methods, call add_converter with your source type and conversion class
macro add_converter(cls,converter)
module ::PG::Types
@@oids_to_crystal_classes[{{converter.id}}.pg_oid]={{converter.id}}
@@oids_to_crystal_classes[{{converter.id}}.pg_array_oid]={{converter.id}}

def self.get_converter(v : {{cls.id}}.class)
{{converter.id}}
end
def self.get_converter(v : Array({{cls.id}}).class)
{{converter.id}}
end
end
{{debug()}}
end

#if we get something from the db and we want to determine the crystal type
def self.oids_to_crystal_classes
@@oids_to_crystal_classes
end

#define a new built-in type
macro type(oid,aoid,cls,name = nil, converter = nil)
@@oids_to_crystal_classes[{{oid}}]=::{{cls.id}}
@@oids_to_crystal_classes[{{aoid}}]=::Array(::{{cls.id}})

def self.get_converter(v : {{cls.id}}.class)
v
end

def self.get_converter(v : Array({{cls.id}}).class)
v
end

{% if cls.resolve < Value %}
struct ::{{cls.id}}
{% unless cls.resolve < ::PG::Types::Converter %}
def self.pg_array
Array({{cls.id}}|Nil)
end
{% end %}
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
{% unless cls.resolve < ::PG::Types::Converter %}
def self.pg_array
Array({{cls.id}}|Nil)
end
{% end %}
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
end #macro

end
end

