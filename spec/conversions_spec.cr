def dbeq(db,a)
db.query("select $1::text,$2,$3::text",
"start",a,"end") do |rs|
rs.each do
rs.read.should eq "start"
rs.read.should eq a
rs.read.should eq "end"
end
end
end

db=PG_DB
i16=[1_i16,1000_i16]
i32=[1_i32,123456_i32]
i64=[1_i64,12341234_i64]
f32=[0.123_f32,2.345_f32]
f64=[4.56789_f64,0.0135_f64]
bool=[true,false]
string=["test","TESTing"]
chars=['a','b']
{% for w in %w(i16 i32 i64 f32 f64 bool string chars) %}
it "should convert {{w.id}}" do
dbeq(db,{{w.id}}[0])
end
it "should convert [{{w.id}}]" do
dbeq(db,{{w.id}})
end
#it "should convert [{{w.id}},nil]" do
#dbeq(db,[{{w.id}}[0],{{w.id}}[1],nil])
#end
{% end %}
