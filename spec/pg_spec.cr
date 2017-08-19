puts "pg_spec"
require "./spec_helper"
require "./driver_spec.cr"
require "./conversions_spec.cr"

describe Pg do
jp=JSON.parse %(
{"test":[true,1,"1",null]}
)
jpa=[jp]*5
it "handles arrays of jsonb" do
PG_DB.query("select $1,$2",
jpa,"test") do |rs|
rs.each do
rs.read.should eq jpa
rs.read.should eq "test"
end
end
end
it "handles jsonb" do
PG_DB.query("select $1",
jp) do |rs|
rs.each do
rs.read.should eq jp
end
end
end

{% if 1 == 0 %}
it "should handle 1m+ rows" do
v=0
endval=400000
PG_DB.query("select x.id::text from (select generate_series(1,#{endval}) id) x") do |rs|
rs.each do
#rv=rs.read(Int32).as(Int32)
rv=rs.read(String).as(String)
#puts rv if rv%10000==0
rv.to_i.should eq v+1
v=rv.to_i
end
end
v.should eq endval
end
{% end %}

  it "works" do
    true.should eq(true)
  end
end
