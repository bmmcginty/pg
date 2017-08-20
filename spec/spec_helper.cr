require "spec"
require "../src/pg"

DB_URL = ENV["DATABASE_URL"]? || "postgres://bmmcginty:bmmcginty@localhost/test"
PG_DB  = DB.open(DB_URL)

def with_db
  DB.open(DB_URL) do |db|
    yield db
  end
end

def with_connection
  DB.connect(DB_URL) do |conn|
    yield conn
  end
end

def escape_literal(string)
  with_connection &.escape_literal(string)
end

def escape_identifier(string)
  with_connection &.escape_identifier(string)
end

module Helper
  def self.db_version_gte(major, minor, patch = 0)
    ver = with_connection &.version
    ver[:major] >= major && ver[:minor] >= minor && ver[:patch] >= patch
  end
end
