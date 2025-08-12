module PG
  class ResultSet < DB::ResultSet
    @query : String?
    @statement : DB::Statement
    @connection : DB::Connection
    @tuple : LibPQ::Result?
    @row_num = -1
    @col_num = 0
    @affected_rows : Int64?
    @io : IO::FileDescriptor
    @first = true
    @eof = false
    @read_timeout : Time::Span? = nil
    @write_timeout : Time::Span? = nil

    setter :flags
    getter :col_num, :row_num, :fd
    getter! :connection, :affected_rows

    def check_open
      raise IO::Error.new("closed connection") if @closed
    end

    def initialize(@statement, @query, @io)
      super statement
      @connection = statement.connection
      @tuple = get_tuple.not_nil!
      gar = get_affected_rows
      gar
    end

    def get_affected_rows
      if @affected_rows
        @affected_rows
      else
        p = LibPQ.cmd_tuples(row)
        s = String.new(p)
        if s == ""
          t = 0_i64
        else
          t = s.to_i64
        end
        @affected_rows = t
        t
      end
    end

    def row
      @tuple.not_nil!
    end

    def row_count : Int32
      LibPQ.ntuples(row)
    end

    def next_column_index : Int32
      @col_num
    end

    def column_count : Int32
      LibPQ.nfields(row)
    end

    def column_name(index : Int) : String
      String.new LibPQ.fname(row, index).dup
    end

    def column_names
      size = column_count
      t = Array(String).new(size)
      size.times do |idx|
        t << column_name(idx)
      end
      t
    end

    def [](key)
      @col_num = 0
      @col_num = column_names.index(key).not_nil!
      read
    end

    def get_io
      @col_num += 1
      if LibPQ.getisnull(row, row_num, col_num - 1) == 1
        return nil
      end
      size = LibPQ.getlength(row, row_num, col_num - 1)
      value = LibPQ.getvalue(row, row_num, col_num - 1)
      IO::Memory.new(value.to_slice(size), writeable: false)
    end

    def st
      LibPQ.result_status(@tuple.not_nil!).to_s
    end

    def stc
      String.new LibPQ.cmd_status(@tuple.not_nil!)
    end

    def read
      typ = LibPQ.ftype(row, col_num)
      begin
        t = Types.oids_to_crystal_classes[typ]
      rescue e
        raise DB::Error.new("pg type #{typ} not supported")
      end
      case t
      when PG::Types::Converter
        read_without_converter t.type
      else
        read_without_converter t
      end
    end

    def read_without_converter(type)
      io = get_io
      return nil unless io
      type.from_pg io.not_nil!
    end

    def read(type)
      t = PG::Types.cr_pg_converter(type)
      read_without_converter t
    end

    protected def do_close
      super
      while move_next
      end
      LibPQ.clear @tuple.not_nil!
      @tuple = nil
    end

    def move_next : Bool
      begin
        t = mmove_next
        return t
      rescue e
        raise e
      end
    end

    def mmove_next
      if @eof == true
        return false
      end
      error = nil
      ret = false
      while 1
        if row_num < (row_count - 1) && row_count > 0
          @row_num += 1
          @col_num = 0
          ret = true
          break
        end
        t = get_tuple
        if t.null?
          @eof = true
          ret = false
          break
        end
        LibPQ.clear row
        @tuple = t.not_nil!
        @row_num = -1
      end
      handle_error
      ret
    end

    def handle_error
      st = LibPQ.result_status(row)
      case st
      when .bad_response?
      when .fatal_error?
        e = String.new(LibPQ.error_message(connection))
        raise DB::Error.new(e)
      end
    end

    def get_tuple : LibPQ::Result
      ret = nil
      while 1
        good = LibPQ.consume_input(@connection)
        # puts "got #{good}"
        if good == 0
          e = String.new LibPQ.error_message(connection)
          raise DB::Error.new(e)
        end
        # puts "getting busy"
        busy = LibPQ.is_busy(@connection)
        # puts "got #{busy}"
        if busy == 0
          # puts "getting result"
          ret = LibPQ.get_result(@connection)
          # puts "got #{ret}"
          break
        end
        # puts "wait readable"
        # puts "wait readable"
        #        Crystal::EventLoop.current.wait_readable(@io)
        # puts "consume input"
      end # while
      ret.not_nil!
    end # def

  end # class

end # module
