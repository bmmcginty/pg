module PG
  struct Notification
    getter channel : String
    getter backend_pid : Int32
    getter payload : String

    def initialize(@channel, @backend_pid, @payload)
    end
  end
end
