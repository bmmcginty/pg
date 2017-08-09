require "db"
require "json"

class Scheduler
def self.ebo
@@eb
end
end

module PG
class Driver < DB::Driver
def build_connection(context : DB::ConnectionContext) : DB::Connection
Connection.new context
end
end
end

DB.register_driver "postgres", PG::Driver
DB.register_driver "postgresql", PG::Driver

