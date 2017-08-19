puts "pg_spec"
require "./spec_helper"
require "./driver_spec.cr"

describe Pg do
jp=JSON.parse %(
{"test":[true,1,"1",null]}
)
it "handles arrays of jsonb" do
jpa=[jp]*5
PG_DB.query("select $1",
jpa) do |rs|
rs.each do
rs.read.should eq jpa
end
end
end
end
it "handles jsonb" do
PG_DB.exec("create table if not exists test (t jsonb)")
#do |rs|
#puts "in block"
#end
PG_DB.exec("insert into test (t) values ($1)",jp)
# do |rs|
#puts "rows:#{rs.row_count}"
#puts "inserted"
#end
#puts "selecting"
PG_DB.query("select t from test") do |rs|
#puts "before read, rows:#{rs.row_count},st:#{rs.st},cst:#{rs.stc}"
rs.each do
t=rs.read(JSON::Any)
#puts "getting #{t}"
t.should eq jp
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
