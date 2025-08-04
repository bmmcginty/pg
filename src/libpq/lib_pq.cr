@[Link(ldflags: "-lpq")]
lib LibPQ
  COPYRES_ATTRS       = 1
  COPYRES_EVENTS      = 4
  COPYRES_NOTICEHOOKS = 8
  COPYRES_TUPLES      = 2
  ErrorsDefault       = 1
  ErrorsTerse         = 0
  ErrorsVerbose       = 2
  PingNoAttempt       = 3
  PingNoResponse      = 2
  PingOk              = 0
  PingReject          = 1
  ShowContextAlways   = 2
  ShowContextErrors   = 1
  ShowContextNever    = 0
  TransActive         = 1
  TransIdle           = 0
  TransInerror        = 3
  TransIntrans        = 2
  TransUnknown        = 4
  alias Oid = LibC::UInt
  alias NoticeProcessor = (Void*, LibC::Char* -> Void)
  alias NoticeReceiver = (Void*, Result -> Void)
  alias ThreadlockT = (LibC::Int -> Void)
  alias Bool = LibC::Char
  alias X_IoLockT = Void
  alias X__Off64T = LibC::Long
  alias X__OffT = LibC::Long
  enum ConnStatusType
    Ok               = 0
    Bad              = 1
    Started          = 2
    Made             = 3
    AwaitingResponse = 4
    AuthOk           = 5
    Setenv           = 6
    SslStartup       = 7
    Needed           = 8
  end
  enum ExecStatusType
    EmptyQuery    = 0
    CommandOk     = 1
    TuplesOk      = 2
    CopyOut       = 3
    CopyIn        = 4
    BadResponse   = 5
    NonfatalError = 6
    FatalError    = 7
    CopyBoth      = 8
    SingleTuple   = 9
  end
  enum ContextVisibility
    ShowContextNever  = 0
    ShowContextErrors = 1
    ShowContextAlways = 2
  end
  enum Ping
    Ok         = 0
    Reject     = 1
    NoResponse = 2
    NoAttempt  = 3
  end
  enum TransactionStatusType
    Idle    = 0
    Active  = 1
    Intrans = 2
    Inerror = 3
    Unknown = 4
  end
  enum Verbosity
    Terse   = 0
    Default = 1
    Verbose = 2
  end
  enum PollingStatusType
    Failed  = 0
    Reading = 1
    Writing = 2
    Ok      = 3
    Active  = 4
  end
  fun backend_pid = PQbackendPID(conn : Conn) : LibC::Int
  fun binary_tuples = PQbinaryTuples(res : Result) : LibC::Int
  fun cancel = PQcancel(cancel : Cancel, errbuf : LibC::Char*, errbufsize : LibC::Int) : LibC::Int
  fun clear = PQclear(res : Result)
  fun client_encoding = PQclientEncoding(conn : Conn) : LibC::Int
  fun cmd_status = PQcmdStatus(res : Result) : LibC::Char*
  fun cmd_tuples = PQcmdTuples(res : Result) : LibC::Char*
  fun conndefaults = PQconndefaults : ConninfoOption*
  fun connect_poll = PQconnectPoll(conn : Conn) : PollingStatusType
  fun connect_start = PQconnectStart(conninfo : LibC::Char*) : Conn
  fun connect_start_params = PQconnectStartParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : LibC::Int) : Conn
  fun connectdb = PQconnectdb(conninfo : LibC::Char*) : Conn
  fun connectdb_params = PQconnectdbParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : LibC::Int) : Conn
  fun connection_needs_password = PQconnectionNeedsPassword(conn : Conn) : LibC::Int
  fun connection_used_password = PQconnectionUsedPassword(conn : Conn) : LibC::Int
  fun conninfo = PQconninfo(conn : Conn) : ConninfoOption*
  fun conninfo_free = PQconninfoFree(conn_options : ConninfoOption*)
  fun conninfo_parse = PQconninfoParse(conninfo : LibC::Char*, errmsg : LibC::Char**) : ConninfoOption*
  fun consume_input = PQconsumeInput(conn : Conn) : LibC::Int
  fun copy_result = PQcopyResult(src : Result, flags : LibC::Int) : Result
  fun db = PQdb(conn : Conn) : LibC::Char*
  fun describe_portal = PQdescribePortal(conn : Conn, portal : LibC::Char*) : Result
  fun describe_prepared = PQdescribePrepared(conn : Conn, stmt : LibC::Char*) : Result
  fun display_tuples = PQdisplayTuples(res : Result, fp : File*, fill_align : LibC::Int, field_sep : LibC::Char*, print_header : LibC::Int, quiet : LibC::Int)
  fun dsplen = PQdsplen(s : LibC::Char*, encoding : LibC::Int) : LibC::Int
  fun encrypt_password = PQencryptPassword(passwd : LibC::Char*, user : LibC::Char*) : LibC::Char*
  fun endcopy = PQendcopy(conn : Conn) : LibC::Int
  fun env2encoding = PQenv2encoding : LibC::Int
  fun error_message = PQerrorMessage(conn : Conn) : LibC::Char*
  fun escape_bytea = PQescapeBytea(from : UInt8*, from_length : LibC::SizeT, to_length : LibC::SizeT*) : UInt8*
  fun escape_bytea_conn = PQescapeByteaConn(conn : Conn, from : UInt8*, from_length : LibC::SizeT, to_length : LibC::SizeT*) : UInt8*
  fun escape_identifier = PQescapeIdentifier(conn : Conn, str : LibC::Char*, len : LibC::SizeT) : LibC::Char*
  fun escape_literal = PQescapeLiteral(conn : Conn, str : LibC::Char*, len : LibC::SizeT) : LibC::Char*
  fun escape_string = PQescapeString(to : LibC::Char*, from : LibC::Char*, length : LibC::SizeT) : LibC::SizeT
  fun escape_string_conn = PQescapeStringConn(conn : Conn, to : LibC::Char*, from : LibC::Char*, length : LibC::SizeT, error : LibC::Int*) : LibC::SizeT
  fun exec = PQexec(conn : Conn, query : LibC::Char*) : Result
  fun exec_params = PQexecParams(conn : Conn, command : LibC::Char*, n_params : LibC::Int, param_types : Oid*, param_values : LibC::Char**, param_lengths : LibC::Int*, param_formats : LibC::Int*, result_format : LibC::Int) : Result
  fun exec_prepared = PQexecPrepared(conn : Conn, stmt_name : LibC::Char*, n_params : LibC::Int, param_values : LibC::Char**, param_lengths : LibC::Int*, param_formats : LibC::Int*, result_format : LibC::Int) : Result
  fun fformat = PQfformat(res : Result, field_num : LibC::Int) : LibC::Int
  fun finish = PQfinish(conn : Conn)
  fun flush = PQflush(conn : Conn) : LibC::Int
  fun fmod = PQfmod(res : Result, field_num : LibC::Int) : LibC::Int
  fun fn = PQfn(conn : Conn, fnid : LibC::Int, result_buf : LibC::Int*, result_len : LibC::Int*, result_is_int : LibC::Int, args : ArgBlock*, nargs : LibC::Int) : Result
  fun fname = PQfname(res : Result, field_num : LibC::Int) : LibC::Char*
  fun fnumber = PQfnumber(res : Result, field_name : LibC::Char*) : LibC::Int
  fun free_cancel = PQfreeCancel(cancel : Cancel)
  fun freemem = PQfreemem(ptr : Void*)
  fun fsize = PQfsize(res : Result, field_num : LibC::Int) : LibC::Int
  fun ftable = PQftable(res : Result, field_num : LibC::Int) : Oid
  fun ftablecol = PQftablecol(res : Result, field_num : LibC::Int) : LibC::Int
  fun ftype = PQftype(res : Result, field_num : LibC::Int) : Oid
  fun get_cancel = PQgetCancel(conn : Conn) : Cancel
  fun get_copy_data = PQgetCopyData(conn : Conn, buffer : LibC::Char**, async : LibC::Int) : LibC::Int
  fun get_result = PQgetResult(conn : Conn) : Result
  fun getisnull = PQgetisnull(res : Result, tup_num : LibC::Int, field_num : LibC::Int) : LibC::Int
  fun getlength = PQgetlength(res : Result, tup_num : LibC::Int, field_num : LibC::Int) : LibC::Int
  fun getline = PQgetline(conn : Conn, string : LibC::Char*, length : LibC::Int) : LibC::Int
  fun getline_async = PQgetlineAsync(conn : Conn, buffer : LibC::Char*, bufsize : LibC::Int) : LibC::Int
  fun getssl = PQgetssl(conn : Conn) : Void*
  fun getvalue = PQgetvalue(res : Result, tup_num : LibC::Int, field_num : LibC::Int) : LibC::Char*
  fun host = PQhost(conn : Conn) : LibC::Char*
  fun init_open_ssl = PQinitOpenSSL(do_ssl : LibC::Int, do_crypto : LibC::Int)
  fun init_ssl = PQinitSSL(do_init : LibC::Int)
  fun is_busy = PQisBusy(conn : Conn) : LibC::Int
  fun isnonblocking = PQisnonblocking(conn : Conn) : LibC::Int
  fun isthreadsafe = PQisthreadsafe : LibC::Int
  fun lib_version = PQlibVersion : LibC::Int
  fun make_empty_p_gresult = PQmakeEmptyResult(conn : Conn, status : ExecStatusType) : Result
  fun mblen = PQmblen(s : LibC::Char*, encoding : LibC::Int) : LibC::Int
  fun nfields = PQnfields(res : Result) : LibC::Int
  fun notifies = PQnotifies(conn : Conn) : Notify*
  fun nparams = PQnparams(res : Result) : LibC::Int
  fun ntuples = PQntuples(res : Result) : LibC::Int
  fun oid_status = PQoidStatus(res : Result) : LibC::Char*
  fun oid_value = PQoidValue(res : Result) : Oid
  fun options = PQoptions(conn : Conn) : LibC::Char*
  fun parameter_status = PQparameterStatus(conn : Conn, param_name : LibC::Char*) : LibC::Char*
  fun paramtype = PQparamtype(res : Result, param_num : LibC::Int) : Oid
  fun pass = PQpass(conn : Conn) : LibC::Char*
  fun ping = PQping(conninfo : LibC::Char*) : Ping
  fun ping_params = PQpingParams(keywords : LibC::Char**, values : LibC::Char**, expand_dbname : LibC::Int) : Ping
  fun port = PQport(conn : Conn) : LibC::Char*
  fun prepare = PQprepare(conn : Conn, stmt_name : LibC::Char*, query : LibC::Char*, n_params : LibC::Int, param_types : Oid*) : Result
  fun print = PQprint(fout : File*, res : Result, ps : PrintOpt*)
  fun print_tuples = PQprintTuples(res : Result, fout : File*, print_att_name : LibC::Int, terse_output : LibC::Int, width : LibC::Int)
  fun protocol_version = PQprotocolVersion(conn : Conn) : LibC::Int
  fun put_copy_data = PQputCopyData(conn : Conn, buffer : LibC::Char*, nbytes : LibC::Int) : LibC::Int
  fun put_copy_end = PQputCopyEnd(conn : Conn, errormsg : LibC::Char*) : LibC::Int
  fun putline = PQputline(conn : Conn, string : LibC::Char*) : LibC::Int
  fun putnbytes = PQputnbytes(conn : Conn, buffer : LibC::Char*, nbytes : LibC::Int) : LibC::Int
  fun register_thread_lock = PQregisterThreadLock(newhandler : ThreadlockT) : ThreadlockT
  fun request_cancel = PQrequestCancel(conn : Conn) : LibC::Int
  fun res_status = PQresStatus(status : ExecStatusType) : LibC::Char*
  fun reset = PQreset(conn : Conn)
  fun reset_poll = PQresetPoll(conn : Conn) : PollingStatusType
  fun reset_start = PQresetStart(conn : Conn) : LibC::Int
  fun result_alloc = PQresultAlloc(res : Result, n_bytes : LibC::SizeT) : Void*
  fun result_error_field = PQresultErrorField(res : Result, fieldcode : LibC::Int) : LibC::Char*
  fun result_error_message = PQresultErrorMessage(res : Result) : LibC::Char*
  fun result_status = PQresultStatus(res : Result) : ExecStatusType
  fun result_verbose_error_message = PQresultVerboseErrorMessage(res : Result, verbosity : Verbosity, show_context : ContextVisibility) : LibC::Char*
  fun send_describe_portal = PQsendDescribePortal(conn : Conn, portal : LibC::Char*) : LibC::Int
  fun send_describe_prepared = PQsendDescribePrepared(conn : Conn, stmt : LibC::Char*) : LibC::Int
  fun send_prepare = PQsendPrepare(conn : Conn, stmt_name : LibC::Char*, query : LibC::Char*, n_params : LibC::Int, param_types : Oid*) : LibC::Int
  fun send_query = PQsendQuery(conn : Conn, query : LibC::Char*) : LibC::Int
  fun send_query_params = PQsendQueryParams(conn : Conn, command : LibC::Char*, n_params : LibC::Int, param_types : Oid*, param_values : LibC::Char**, param_lengths : LibC::Int*, param_formats : LibC::Int*, result_format : LibC::Int) : LibC::Int
  fun send_query_prepared = PQsendQueryPrepared(conn : Conn, stmt_name : LibC::Char*, n_params : LibC::Int, param_values : LibC::Char**, param_lengths : LibC::Int*, param_formats : LibC::Int*, result_format : LibC::Int) : LibC::Int
  fun server_version = PQserverVersion(conn : Conn) : LibC::Int
  fun set_client_encoding = PQsetClientEncoding(conn : Conn, encoding : LibC::Char*) : LibC::Int
  fun set_error_context_visibility = PQsetErrorContextVisibility(conn : Conn, show_context : ContextVisibility) : ContextVisibility
  fun set_error_verbosity = PQsetErrorVerbosity(conn : Conn, verbosity : Verbosity) : Verbosity
  fun set_notice_processor = PQsetNoticeProcessor(conn : Conn, proc : NoticeProcessor, arg : Void*) : NoticeProcessor
  fun set_notice_receiver = PQsetNoticeReceiver(conn : Conn, proc : NoticeReceiver, arg : Void*) : NoticeReceiver
  fun set_result_attrs = PQsetResultAttrs(res : Result, num_attributes : LibC::Int, att_descs : AttDesc*) : LibC::Int
  fun set_single_row_mode = PQsetSingleRowMode(conn : Conn) : LibC::Int
  fun setdb_login = PQsetdbLogin(pghost : LibC::Char*, pgport : LibC::Char*, pgoptions : LibC::Char*, pgtty : LibC::Char*, db_name : LibC::Char*, login : LibC::Char*, pwd : LibC::Char*) : Conn
  fun setnonblocking = PQsetnonblocking(conn : Conn, arg : LibC::Int) : LibC::Int
  fun setvalue = PQsetvalue(res : Result, tup_num : LibC::Int, field_num : LibC::Int, value : LibC::Char*, len : LibC::Int) : LibC::Int
  fun socket = PQsocket(conn : Conn) : LibC::Int
  fun ssl_attribute = PQsslAttribute(conn : Conn, attribute_name : LibC::Char*) : LibC::Char*
  fun ssl_attribute_names = PQsslAttributeNames(conn : Conn) : LibC::Char**
  fun ssl_in_use = PQsslInUse(conn : Conn) : LibC::Int
  fun ssl_struct = PQsslStruct(conn : Conn, struct_name : LibC::Char*) : Void*
  fun status = PQstatus(conn : Conn) : ConnStatusType
  fun trace = PQtrace(conn : Conn, debug_port : File*)
  fun transaction_status = PQtransactionStatus(conn : Conn) : TransactionStatusType
  fun tty = PQtty(conn : Conn) : LibC::Char*
  fun unescape_bytea = PQunescapeBytea(strtext : UInt8*, retbuflen : LibC::SizeT*) : UInt8*
  fun untrace = PQuntrace(conn : Conn)
  fun user = PQuser(conn : Conn) : LibC::Char*

  struct Notify
    relname : LibC::Char*
    be_pid : LibC::Int
    extra : LibC::Char*
    next : Notify*
  end

  struct AttDesc
    name : LibC::Char*
    tableid : Oid
    columnid : LibC::Int
    format : LibC::Int
    typid : Oid
    typlen : LibC::Int
    atttypmod : LibC::Int
  end

  struct ArgBlock
    len : LibC::Int
    isint : LibC::Int
    u : ArgBlockU
  end

  struct X_IoFile
    _flags : LibC::Int
    _io_read_ptr : LibC::Char*
    _io_read_end : LibC::Char*
    _io_read_base : LibC::Char*
    _io_write_base : LibC::Char*
    _io_write_ptr : LibC::Char*
    _io_write_end : LibC::Char*
    _io_buf_base : LibC::Char*
    _io_buf_end : LibC::Char*
    _io_save_base : LibC::Char*
    _io_backup_base : LibC::Char*
    _io_save_end : LibC::Char*
    _markers : X_IoMarker*
    _chain : X_IoFile*
    _fileno : LibC::Int
    _flags2 : LibC::Int
    _old_offset : X__OffT
    _cur_column : LibC::UShort
    _vtable_offset : LibC::Char
    _shortbuf : LibC::Char[1]
    _lock : X_IoLockT*
    _offset : X__Off64T
    __pad1 : Void*
    __pad2 : Void*
    __pad3 : Void*
    __pad4 : Void*
    __pad5 : LibC::SizeT
    _mode : LibC::Int
    _unused2 : LibC::Char[20]
  end

  struct X_IoMarker
    _next : X_IoMarker*
    _sbuf : X_IoFile*
    _pos : LibC::Int
  end

  struct ConninfoOption
    keyword : LibC::Char*
    envvar : LibC::Char*
    compiled : LibC::Char*
    val : LibC::Char*
    label : LibC::Char*
    dispchar : LibC::Char*
    dispsize : LibC::Int
  end

  struct PrintOpt
    header : Bool
    align : Bool
    standard : Bool
    html3 : Bool
    expanded : Bool
    pager : Bool
    field_sep : LibC::Char*
    table_opt : LibC::Char*
    caption : LibC::Char*
    field_name : LibC::Char**
  end

  type File = X_IoFile
  type Cancel = Void*
  type Conn = Void*
  type Result = Void*

  union ArgBlockU
    ptr : LibC::Int*
    integer : LibC::Int
  end
end
