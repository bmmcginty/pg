require "json"

module PG::Types
#All the possible types, either base crystal types, or converters
alias Tt=\
Char.class|Nil.class|Int16.class|Int32.class|Int64.class|Float32.class|Float64.class|String.class|Time.class|Bool.class|
Array(Char).class|Array(Nil).class|Array(Int16).class|Array(Int32).class|Array(Int64).class|Array(Float32).class|Array(Float64).class|Array(String).class|Array(Time).class|Array(Bool).class|
Converter

@@oids_to_crystal_classes=Hash(Int32,Tt).new
#if we get something from the db and we want to determine the crystal type
def self.oids_to_crystal_classes
@@oids_to_crystal_classes
end

#if you want to override the to_pg and from_pg methods, call add_converter with your source type and conversion class
macro add_converter(cls,converter)
#no array
class {{converter.id}}_na < {{converter.id}}
def self.type
{{cls.id}}
end
end
class {{converter.id}}_a < {{converter.id}}
def self.type
Array({{cls.id}})
end
end

module PG::Types
@@oids_to_crystal_classes[{{converter.id}}.pg_oid]={{converter.id}}_na.new
@@oids_to_crystal_classes[{{converter.id}}.pg_array_oid]={{converter.id}}_a.new

def self.cr_pg_converter(v : {{cls.id}}.class)
{{converter.id}}
end #def
def self.cr_pg_converter(v : Array({{cls.id}}).class)
Array({{converter.id}})
end #def
end #module

class {{converter.id}}
def self.to_pg(obj : {{cls}})
io=IO::Memory.new
self.to_pg io: io, obj: obj
{ format: :binary, value: io }
end #def
end #class
end #macro

#define a new built-in type
macro type(oid,aoid,cls,name = nil, converter = nil)
@@oids_to_crystal_classes[{{oid}}]=::{{cls.id}}
@@oids_to_crystal_classes[{{aoid}}]=::Array(::{{cls.id}})

def self.cr_pg_converter(v : {{cls.id}}.class)
v
end

def self.cr_pg_converter(v : Array({{cls.id}}).class)
v
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
end #macro

end

