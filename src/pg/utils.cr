module PG
module IOUtils
macro included
{% for mode in %w(r w rw) %}
@event_{{mode.id}} : Event::Event? = nil
def create_event_{{mode.id}}(fd)
ev = if @event_{{mode.id}}
@event_{{mode.id}}
else
flags=LibEvent2::EventFlags::None
{% if mode.id == :r %}
flags = LibEvent2::EventFlags::Read
{% elsif mode.id == :w %}
flags = LibEvent2::EventFlags::Write
{% elsif mode.id == :rw %}
flags = LibEvent2::EventFlags::Read|LibEvent2::EventFlags::Write
{% else %}
{{raise "invalid mode " + mode }}
{% end %}
tev=Scheduler.ebo.new_event(fd,flags,self) do |s,flags,data|
c=data.as({{@type.name.id}})
t=""
if flags.includes?(LibEvent2::EventFlags::Read)
t+="r"
end
if flags.includes?(LibEvent2::EventFlags::Write)
t+="w"
end
c.flags=t
c.resume
end
@event_{{mode.id}}=tev
tev
end
ev.not_nil!.add
ev.not_nil!
end
{% end %}

def close_events
{% for mode in %w(r w rw) %}
if @event_{{mode.id}} != nil
@event_{{mode.id}}.not_nil!.free
@event_{{mode.id}}=nil
end
{% end %}
end #def
end #macro
end #module
end #module


