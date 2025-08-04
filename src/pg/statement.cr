module PG
  class Statement < DB::Statement
    protected def perform_exec(args : Enumerable) : DB::ExecResult
      pq = perform_query(args)
      pq.do_close
      ar = pq.affected_rows
      ::DB::ExecResult.new(
        rows_affected: ar,
        last_insert_id: 0_i64
      )
    end

    def do_convert(instance, cls : PG::Types::Converter.class)
      {cls.pg_oid, cls.to_pg(instance)}
    end

    def do_convert(instance, cls)
      {cls.pg_oid, instance.to_pg}
    end

    protected def perform_query(args : Enumerable) : DB::ResultSet
      paramTypes = Array(UInt32).new(args.size)
      paramFormats = Array(Int32).new(args.size)
      paramValues = Pointer(Pointer(UInt8)).malloc(args.size)
      paramLengths = Array(Int32).new(args.size)
      idx = -1
      args.each do |i|
        next if i.is_a?(Slice(UInt8))
        idx += 1
        converter = Types.cr_pg_converter(i.class)
        oid, conv = do_convert(i, converter)
        paramTypes << oid.to_u32
        paramFormats << ((conv[:format] == :text) ? 0_i32 : 1_i32)
        paramLengths << conv[:value].as(IO::Memory).size
        pv = conv[:value].as(IO::Memory)
        paramValues[idx] = if i != nil
                             pv.to_slice.to_unsafe
                           else
                             Pointer(UInt8).null
                           end
      end
      resultFormat = 1 # binary
      # idx+1 was args.size
      rv = LibPQ.send_query_params(connection, @command, idx + 1, paramTypes, paramValues, paramLengths, paramFormats, resultFormat)
      connection.handle_send
      if rv == 0
        em = String.new LibPQ.error_message(connection)
        raise DB::Error.new em
      end
      # LibPQ.set_single_row_mode connection
      ResultSet.new self, @command
    end # perform_query

  end
end
