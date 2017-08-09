module PG
module Types
class Converter
def self.from_pg(io : IO::Memory)
raise DB::Error.new("impl")
end
def self.to_pg(obj)
raise DB::Error.new("impl")
end
end

alias Tt=Int8.class|Int16.class|Int32.class|Int64.class|Float32.class|Float64.class|String.class|Time.class|Nil.class|Bool.class|JSON::Any.class
#def initialize
@@types=Hash(Int32,Tt).new
@@types_rev=Hash(Tt,Int32).new
@@type_names=Hash(Symbol,Int32).new
@@overrides = Hash(Tt,Int32).new
@@converters = Hash(Int32,Converter.class).new

macro type(oid,aoid,cls,name = nil, converter = nil)
@@types[{{oid}}]={{cls}}
@@types_rev[{{cls}}]={{oid}}
{% if name %}
@@type_names[{{name}}]={{oid}}
{% end %}
{% if converter %}
@@converters[{{oid}}]={{converter}}.as(::PG::Types::Converter.class)
{% end %}
end

#get class from oid
def self.get_class(oid : Int32)
@@types[oid]
end

#get converter if available
def self.get_converter?(cls : Tt)
@@converters[self.get_oid(cls)]?
end

#lookup oid for cr to pg
def self.get_oid(cls : Tt)
if @@overrides.has_key?(cls)
@@overrides[cls]
else
@@types_rev[cls]
end
end

def self.override(cls : Tt, name : String)
oid=@@type_names[name]
@@overrides[cls]=oid
end

type 16,1000,Bool,:bool
type 23,1007,Int32,:int32
type 18,1002,String,:char
type 20,1016,Int64,:int64
type 21,1005,Int16,:int16
type 25,1009,String,:text
type 114,199,JSON::Any,:json
type 700,1021,Float32,:float32
type 701,1022,Float64,:float64
type 3802,3807,JSON::Any,:jsonb,PG::Types::JSONB
type 1114,1115,Time,:time

<<-EOF
17,Bytea,
1001,Array(Bytea),
19,Name,
1003,Array(Name),
22,Int2vector,
1006,Array(Int2vector),
24,Regproc,
1008,Array(Regproc),
26,Oid,
1028,Array(Oid),
27,Tid,
1010,Array(Tid),
28,Xid,
1011,Array(Xid),
29,Cid,
1012,Array(Cid),
30,Oidvector,
1013,Array(Oidvector),
142,Xml,
143,Array(Xml),
194,PgNodeTree,
0,Array(PgNodeTree),
210,Smgr,
0,Array(Smgr),
600,Point,
1017,Array(Point),
601,Lseg,
1018,Array(Lseg),
602,Path,
1019,Array(Path),
603,Box,
1020,Array(Box),
604,Polygon,
1027,Array(Polygon),
628,Line,
629,Array(Line),
650,Cidr,
651,Array(Cidr),
702,Abstime,
1023,Array(Abstime),
703,Reltime,
1024,Array(Reltime),
704,Tinterval,
1025,Array(Tinterval),
705,Unknown,
0,Array(Unknown),
718,Circle,
719,Array(Circle),
790,Money,
791,Array(Money),
829,Macaddr,
1040,Array(Macaddr),
869,Inet,
1041,Array(Inet),
1033,Aclitem,
1034,Array(Aclitem),
1042,Bpchar,
1014,Array(Bpchar),
1043,Varchar,
1015,Array(Varchar),
1082,Date,
1182,Array(Date),
1083,Time,
1183,Array(Time),
1184,Timestamptz,
1185,Array(Timestamptz),
1186,Interval,
1187,Array(Interval),
1266,Timetz,
1270,Array(Timetz),
1560,Bit,
1561,Array(Bit),
1562,Varbit,
1563,Array(Varbit),
1700,Numeric,
1231,Array(Numeric),
1790,Refcursor,
2201,Array(Refcursor),
2202,Regprocedure,
2207,Array(Regprocedure),
2203,Regoper,
2208,Array(Regoper),
2204,Regoperator,
2209,Array(Regoperator),
2205,Regclass,
2210,Array(Regclass),
2206,Regtype,
2211,Array(Regtype),
2950,Uuid,
2951,Array(Uuid),
2970,TxidSnapshot,
2949,Array(TxidSnapshot),
3220,PgLsn,
3221,Array(PgLsn),
3614,Tsvector,
3643,Array(Tsvector),
3615,Tsquery,
3645,Array(Tsquery),
3642,Gtsvector,
3644,Array(Gtsvector),
3734,Regconfig,
3735,Array(Regconfig),
3769,Regdictionary,
3770,Array(Regdictionary),
4089,Regnamespace,
4090,Array(Regnamespace),
4096,Regrole,
4097,Array(Regrole),
16629,QueryInt,
16632,Array(QueryInt),
16697,IntbigGkey,
16700,Array(IntbigGkey)
}
EOF
end
end

