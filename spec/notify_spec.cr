require "./spec_helper"

private def notify_channel
  "pg_notify_#{Process.pid}_#{Random.rand(1_000_000)}"
end

describe PG::Notification do
  it "receives pending notifications" do
    channel = notify_channel
    payload = "payload-#{Random.rand(1_000_000)}"

    DB.connect(DB_URL) do |listener_conn|
      listener = listener_conn.as(PG::Connection)
      listener.exec "LISTEN #{channel}"

      DB.connect(DB_URL) do |sender|
        sender.exec "select pg_notify($1, $2)", channel, payload
      end

      notification = listener.wait_for_notification
      notification.channel.should eq(channel)
      notification.payload.should eq(payload)
      notification.backend_pid.should be > 0
      listener.notification?.should be_nil
    end
  end

  it "waits for notifications without blocking other fibers" do
    channel = notify_channel
    payload = "wait-payload-#{Random.rand(1_000_000)}"
    notifications = Channel(PG::Notification).new

    DB.connect(DB_URL) do |listener_conn|
      listener = listener_conn.as(PG::Connection)
      listener.exec "LISTEN #{channel}"

      spawn do
        notifications.send listener.wait_for_notification
      end

      select
      when notifications.receive
        fail "received a notification before NOTIFY was sent"
      when timeout(50.milliseconds)
      end

      DB.connect(DB_URL) do |sender|
        sender.exec "select pg_notify($1, $2)", channel, payload
      end

      select
      when notification = notifications.receive
        notification.channel.should eq(channel)
        notification.payload.should eq(payload)
      when timeout(2.seconds)
        fail "timed out waiting for notification"
      end
    end
  end
end
