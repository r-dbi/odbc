//! \file nanodbc.cpp Implementation details.

#include "nanodbc.h"

#include <cassert>
#include <cstdio>
#include <map>

#define NANODBC_STRINGIZE_I(text) #text
#define NANODBC_STRINGIZE(text) NANODBC_STRINGIZE_I(text)
#define NANODBC_THROW_DATABASE_ERROR(handle, handle_type) throw database_error(handle, handle_type, __FILE__ ":" NANODBC_STRINGIZE(__LINE__) ": ")

#ifdef NANODBC_ODBC_API_DEBUG
    #include <iostream>
    #define NANODBC_CALL(FUNC, RC, ...)                                                            \
        do {                                                                                       \
            std::cerr << __FILE__ << ":" NANODBC_STRINGIZE(__LINE__) << " " << #FUNC << std::endl; \
            RC = FUNC(__VA_ARGS__);                                                                \
        } while(false)                                                                             \
        /**/
#else
    #define NANODBC_CALL(FUNC, RC, ...) RC = FUNC(__VA_ARGS__)
#endif

namespace nanodbc
{

namespace detail
{
    const char* const sql_type_info<short>::format = "%hd";
    const char* const sql_type_info<unsigned short>::format = "%hu";
    const char* const sql_type_info<long>::format = "%ld";
    const char* const sql_type_info<unsigned long>::format = "%lu";
    const char* const sql_type_info<int>::format = "%d";
    const char* const sql_type_info<unsigned int>::format = "%u";
    const char* const sql_type_info<float>::format = "%f";
    const char* const sql_type_info<double>::format = "%lf";
    const char* const sql_type_info<std::string>::format = "%s";
} // namespace detail

using namespace detail;

namespace
{
    // Converts the given string to the given type T.
    template<class T>
    inline T convert(const std::string& s)
    {
        T value;
        std::sscanf(s.c_str(), sql_type_info<T>::format, &value);
        return value;
    }

    // easy way to check if a return code signifies success.
    inline bool success(RETCODE rc)
    {
        return rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO;
    }

    class bound_column
    {
    public:
        bound_column()
        : name_()
        , sqltype_(0)
        , sqlsize_(0)
        , scale_(0)
        , ctype_(0)
        , clen_(0)
        , blob_(false)
        , rowset_size_(0)
        , cbdata_(0)
        , pdata_(0)
        {

        }

        ~bound_column()
        {
            delete[] cbdata_;
            delete[] pdata_;
        }

    public:
        std::string name_;
        SQLSMALLINT sqltype_;
        SQLULEN sqlsize_;
        SQLSMALLINT scale_;
        SQLSMALLINT ctype_;
        SQLSMALLINT clen_;
        bool blob_;
        long rowset_size_;
        long* cbdata_;
        char* pdata_;

    private:
        bound_column(const bound_column& rhs); // not defined
        bound_column& operator=(bound_column rhs); // not defined
    };

    class bound_parameter
    {
    public:
        bound_parameter(HSTMT stmt, long param)
        : stmt_(stmt)
        , param_(param)
        , value_buffer_(0)
        , value_buffer_len_(0)
        , string_buffer_()
        , string_buffer_len_(0)
        {

        }

        ~bound_parameter()
        {
            delete[] value_buffer_;
        }

        bound_parameter(const bound_parameter& rhs)
        : stmt_(rhs.stmt_)
        , param_(rhs.param_)
        , value_buffer_(rhs.value_buffer_)
        , value_buffer_len_(rhs.value_buffer_len_)
        , string_buffer_(rhs.string_buffer_)
        , string_buffer_len_(rhs.string_buffer_len_)
        {

        }

        bound_parameter& operator=(bound_parameter rhs)
        {
            swap(rhs);
            return *this;
        }

        void swap(bound_parameter& rhs)
        {
            using std::swap;
            swap(stmt_, rhs.stmt_);
            swap(param_, rhs.param_);
            swap(value_buffer_, rhs.value_buffer_);
            swap(value_buffer_len_, rhs.value_buffer_len_);
            swap(string_buffer_, rhs.string_buffer_);
            swap(string_buffer_len_, rhs.string_buffer_len_);
        }

        void set_value(SQLSMALLINT ctype, SQLSMALLINT sqltype, char* data, std::size_t element_size, std::size_t elements, bool take_ownership)
        {
            delete[] value_buffer_;
            if(take_ownership)
            {
                value_buffer_ = data;
            }
            else
            {
                value_buffer_ = new char[element_size * elements];
                using std::copy;
                copy(data, data + (element_size * elements), value_buffer_);
            }
            value_buffer_len_ = element_size * elements;
            RETCODE rc;
            NANODBC_CALL(SQLBindParameter, rc, 
                stmt_
                , param_ + 1
                , SQL_PARAM_INPUT
                , ctype
                , sqltype
                , element_size // column size ignored for many types, but needed for strings
                , 0
                , (SQLPOINTER)value_buffer_
                , element_size
                , 0);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        }

        void set_string(const std::string& str)
        {
            string_buffer_ = str;
            string_buffer_len_ = SQL_NTS;
            RETCODE rc;
            NANODBC_CALL(SQLBindParameter, rc, 
                stmt_
                , param_ + 1
                , SQL_PARAM_INPUT
                , sql_type_info<std::string>::ctype
                , sql_type_info<std::string>::sqltype
                , (SQLUINTEGER)string_buffer_.size()
                , 0
                , (SQLPOINTER*)string_buffer_.c_str()
                , (SQLLEN)string_buffer_.size() + 1
                , &string_buffer_len_);
            if (!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        }

    private:
        HSTMT stmt_;
        long param_;
        char* value_buffer_;
        long value_buffer_len_;
        std::string string_buffer_;
        SQLLEN string_buffer_len_;
    };

    // attempts to get the last ODBC error as a string.
    inline std::string last_error(SQLHANDLE handle, SQLSMALLINT handle_type)
    {
        SQLCHAR sql_state[6];
        SQLCHAR sql_message[SQL_MAX_MESSAGE_LENGTH];
        SQLINTEGER native_error;
        SQLSMALLINT total_bytes;
        RETCODE rc = SQLGetDiagRec(
            handle_type
            , handle
            , 1
            , sql_state
            , &native_error
            , sql_message
            , sizeof(sql_message) 
            , &total_bytes);
        if(success(rc))
        {
            std::string error = reinterpret_cast<char*>(sql_message);
            std::string status = reinterpret_cast<char*>(sql_state);
            return status + ": " + error;
        }
        return "Unknown Error: SQLGetDiagRec() call failed";
    }

    // allocates the native ODBC handles.
    inline void allocate_handle(HENV& env, HDBC& conn)
    {
        RETCODE rc;
        NANODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        NANODBC_CALL(SQLSetEnvAttr, rc, env, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, SQL_IS_UINTEGER);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        NANODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env, &conn);   
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);
    }
} // namespace

type_incompatible_error::type_incompatible_error()
: std::runtime_error("type incompatible") { }

const char* type_incompatible_error::what() const throw()
{
    return std::runtime_error::what();
}

null_access_error::null_access_error()
: std::runtime_error("null access") { }

const char* null_access_error::what() const throw()
{
    return std::runtime_error::what();
}

index_range_error::index_range_error()
: std::runtime_error("index out of range") { }

const char* index_range_error::what() const throw()
{
    return std::runtime_error::what();
}

database_error::database_error(SQLHANDLE handle, SQLSMALLINT handle_type, const std::string& info)
: std::runtime_error(info + last_error(handle, handle_type)) { }

const char* database_error::what() const throw()
{
    return std::runtime_error::what();
}

class connection::connection_impl
{
public:
    connection_impl()
    : env_(0)
    , conn_(0)
    , connected_(false)
    , transactions_(0)
    , rollback_(false)
    {
        allocate_handle(env_, conn_);
    }

    connection_impl(const std::string& dsn, const std::string& user, const std::string& pass, long timeout)
    : env_(0)
    , conn_(0)
    , connected_(false)
    , transactions_(0)
    , rollback_(false)
    {
        allocate_handle(env_, conn_);
        connect(dsn, user, pass, timeout);
    }

    connection_impl(const std::string& connection_string, long timeout)
    : env_(0)
    , conn_(0)
    , connected_(false)
    , transactions_(0)
    , rollback_(false)
    {
        allocate_handle(env_, conn_);
        connect(connection_string, timeout);
    }

    ~connection_impl() throw()
    {
        disconnect();
        RETCODE rc;
        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_ENV, env_);
    }

    void connect(const std::string& dsn, const std::string& user, const std::string& pass, long timeout)
    {
        disconnect();

        RETCODE rc;
        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env_, SQL_HANDLE_ENV);

        NANODBC_CALL(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, (SQLPOINTER)timeout, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL(SQLConnect, rc,
            conn_
            , (SQLCHAR*)dsn.c_str(), SQL_NTS
            , user.empty() ? (SQLCHAR*)user.c_str() : 0, SQL_NTS
            , pass.empty() ? (SQLCHAR*)pass.c_str() : 0, SQL_NTS);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        connected_ = success(rc);
    }

    void connect(const std::string& connection_string, long timeout)
    {
        disconnect();

        RETCODE rc;
        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env_, SQL_HANDLE_ENV);

        NANODBC_CALL(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, (SQLPOINTER)timeout, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        SQLCHAR dsn[1024];
        SQLSMALLINT dsn_size = 0;
        NANODBC_CALL(SQLDriverConnect, rc,
            conn_
            , 0
            , (SQLCHAR*)connection_string.c_str(), SQL_NTS
            , dsn, sizeof(dsn)
            , &dsn_size
            , SQL_DRIVER_NOPROMPT);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        connected_ = success(rc);
    }

    bool connected() const
    {
        return connected_;
    }

    void disconnect() throw()
    {
        if(connected())
        {
            SQLDisconnect(conn_);
        }
        connected_ = false;
    }

    std::size_t transactions() const
    {
        return transactions_;
    }

    HDBC native_dbc_handle() const
    {
        return conn_;
    }

    HDBC native_env_handle() const
    {
        return env_;
    }

    std::string driver_name() const
    {
        char name[1024];
        SQLSMALLINT length;
        RETCODE rc;
        NANODBC_CALL(SQLGetInfo, rc, conn_, SQL_DRIVER_NAME, name, sizeof(name), &length);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
        return name;
    }

    std::size_t ref_transaction()
    {
        return --transactions_;
    }

    std::size_t unref_transaction()
    {
        return ++transactions_;
    }

    bool rollback() const
    {
        return rollback_;
    }

    void rollback(bool onoff)
    {
        rollback_ = onoff;
    }

private:
    connection_impl(const connection_impl&); // not defined
    connection_impl& operator=(const connection_impl&); // not defined

private:
    HENV env_;
    HDBC conn_;
    bool connected_;
    std::size_t transactions_;
    bool rollback_; // if true, this connection is marked for eventual transaction rollback
};

class transaction::transaction_impl
{
public:
    transaction_impl(const class connection& conn)
    : conn_(conn)
    , committed_(false)
    {
        if(conn_.transactions() == 0 && conn_.connected())
        {
            RETCODE rc;
            NANODBC_CALL(SQLSetConnectAttr, rc,
                conn_.native_dbc_handle()
                , SQL_ATTR_AUTOCOMMIT
                , (SQLPOINTER)SQL_AUTOCOMMIT_OFF
                , SQL_IS_UINTEGER);
            if (!success(rc))
                NANODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
        }
        conn_.ref_transaction();
    }

    ~transaction_impl() throw()
    {
        if(!committed_)
        {
            conn_.rollback(true);
            conn_.unref_transaction();
        }

        if(conn_.transactions() == 0 && conn_.rollback() && conn_.connected())
        {
            RETCODE rc;
            NANODBC_CALL(SQLEndTran, rc, SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_ROLLBACK);
            conn_.rollback(false);
            NANODBC_CALL(SQLSetConnectAttr, rc, 
                conn_.native_dbc_handle()
                , SQL_ATTR_AUTOCOMMIT
                , (SQLPOINTER)SQL_AUTOCOMMIT_ON
                , SQL_IS_UINTEGER);
        }
    }

    void commit()
    {
        if(committed_)
            return;
        committed_ = true;
        if(conn_.unref_transaction() == 0 && conn_.connected())
        {
            RETCODE rc;
            NANODBC_CALL(SQLEndTran, rc, SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_COMMIT);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
        }
    }

    void rollback() throw()
    {
        if(committed_)
            return;
        conn_.rollback(true);
    }

    class connection& connection()
    {
        return conn_;
    }

    const class connection& connection() const
    {
        return conn_;
    }

private:
    transaction_impl(const transaction_impl&); // not defined
    transaction_impl& operator=(const transaction_impl&); // not defined

private:
    class connection conn_;
    bool committed_;
};

class statement::statement_impl
{
private:
    typedef std::map<long, bound_parameter*> bound_parameters_type;

public:
    statement_impl()
    : stmt_(0)
    , open_(false)
    , bound_parameters_()
    {

    }

    statement_impl(connection& conn, const std::string& stmt)
    : stmt_(0)
    , open_(false)
    , bound_parameters_()
    {
        prepare(conn, stmt);
    }

    ~statement_impl() throw()
    {
        if(!open())
            return;
        RETCODE rc;
        NANODBC_CALL(SQLCancel, rc, stmt_);
        reset_parameters();
        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_STMT, stmt_);
    }

    void open(connection& conn)
    {
        close();
        RETCODE rc;
        NANODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_STMT, conn.native_dbc_handle(), &stmt_);
        open_ = success(rc);
        if (!open_)
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

    bool open() const
    {
        return open_;
    }

    HDBC native_stmt_handle() const
    {
        return stmt_;
    }

    void close()
    {
        if(!open())
            return;
        RETCODE rc;
        NANODBC_CALL(SQLCancel, rc, stmt_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        reset_parameters();

        NANODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_STMT, stmt_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        open_ = false;
        stmt_ = 0;
    }

    void cancel()
    {
        RETCODE rc;
        NANODBC_CALL(SQLCancel, rc, stmt_);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

    void prepare(connection& conn, const std::string& stmt)
    {
        open(conn);
        RETCODE rc;
        NANODBC_CALL(SQLPrepare, rc, stmt_, (SQLCHAR*)stmt.c_str(), SQL_NTS);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

    result execute_direct(connection& conn, const std::string& query, long batch_operations, statement& statement)
    {
        open(conn);
        RETCODE rc;
        NANODBC_CALL(SQLSetStmtAttr, rc, stmt_, SQL_ATTR_PARAMSET_SIZE, (SQLPOINTER)batch_operations, 0);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        NANODBC_CALL(SQLExecDirect, rc, stmt_, (SQLCHAR*)query.c_str(), SQL_NTS);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return result(statement, batch_operations);
    }

    result execute(long batch_operations, statement& statement)
    {
        RETCODE rc;
        NANODBC_CALL(SQLSetStmtAttr, rc, stmt_, SQL_ATTR_PARAMSET_SIZE, (SQLPOINTER)batch_operations, 0);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        NANODBC_CALL(SQLExecute, rc, stmt_);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return result(statement, batch_operations);
    }

    long affected_rows() const
    {
        SQLLEN rows;
        RETCODE rc;
        NANODBC_CALL(SQLRowCount, rc, stmt_, &rows);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return rows;
    }

    void reset_parameters() throw()
    {
        RETCODE rc;
        NANODBC_CALL(SQLFreeStmt, rc, stmt_, SQL_RESET_PARAMS);
        for(bound_parameters_type::iterator i = bound_parameters_.begin(), end = bound_parameters_.end(); i != end; ++i)
            delete i->second;
        bound_parameters_.clear();
    }

    template<class T>
    void bind_parameter(long param, const T& value)
    {
        bind_parameter(
            param
            , sql_type_info<T>::ctype
            , sql_type_info<T>::sqltype
            , (char*)&value
            , sizeof(value)
            , 1
            , false);
    }

    void bind_parameter(long param, const std::string& value)
    {
        if(!bound_parameters_.count(param))
            bound_parameters_[param] = new bound_parameter(stmt_, param);
        bound_parameters_[param]->set_string(value);
    }

    unsigned long parameter_column_size(long param) const
    {
        RETCODE rc;
        SQLULEN column_size;
        SQLSMALLINT data_type;
        SQLSMALLINT decimal_digits;
        SQLSMALLINT nullable;
        NANODBC_CALL(SQLDescribeParam, rc, stmt_, param + 1, &data_type, &column_size, &decimal_digits, &nullable);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return column_size;
    }

    void bind_parameter(
        long param
        , SQLSMALLINT ctype
        , SQLSMALLINT sqltype
        , char* data
        , std::size_t element_size
        , std::size_t elements
        , bool take_ownership)
    {
        if(!bound_parameters_.count(param))
            bound_parameters_[param] = new bound_parameter(stmt_, param);
        bound_parameters_[param]->set_value(ctype, sqltype, data, element_size, elements, take_ownership);
    }

private:
    statement_impl(const statement_impl&); // not defined
    statement_impl& operator=(const statement_impl&); // not defined

private:
    HSTMT stmt_;
    bool open_;
    bound_parameters_type bound_parameters_;
};

class result::result_impl
{
public:
    result_impl(statement stmt, long rowset_size)
    : stmt_(stmt)
    , rowset_size_(rowset_size)
    , row_count_(0)
    , bound_columns_(0)
    , bound_columns_size_(0)
    {
        RETCODE rc;
        NANODBC_CALL(SQLSetStmtAttr, rc, stmt_.native_stmt_handle(), SQL_ATTR_ROW_ARRAY_SIZE, (SQLPOINTER)rowset_size_, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);

        NANODBC_CALL(SQLSetStmtAttr, rc, stmt_.native_stmt_handle(), SQL_ATTR_ROWS_FETCHED_PTR, &row_count_, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);

        auto_bind();
    }

    ~result_impl() throw()
    {
        before_move();
        delete[] bound_columns_;
    }

    HDBC native_stmt_handle() const
    {
        return stmt_.native_stmt_handle();
    }

    long rowset_size() const
    {
        return rowset_size_;
    }

    long affected_rows() const
    {
        SQLLEN rows;
        RETCODE rc;
        NANODBC_CALL(SQLRowCount, rc, stmt_.native_stmt_handle(), &rows);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
        return rows;
    }

    long rows() const
    {
        return row_count_;
    }

    short columns() const
    {
        SQLSMALLINT cols;
        RETCODE rc;
        NANODBC_CALL(SQLNumResultCols, rc, stmt_.native_stmt_handle(), &cols);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
        return cols;
    }

    bool first()
    {
        return fetch(0, SQL_FETCH_FIRST);
    }

    bool last()
    {
        return fetch(0, SQL_FETCH_LAST);
    }

    bool next()
    {
        return fetch(0, SQL_FETCH_NEXT);
    }

    bool prior()
    {
        return fetch(0, SQL_FETCH_PRIOR);
    }

    bool move(long row)
    {
        return fetch(row, SQL_FETCH_ABSOLUTE);
    }

    bool skip(long rows)
    {
        return fetch(rows, SQL_FETCH_RELATIVE);
    }

    long position() const
    {
        SQLULEN pos;
        RETCODE rc;
        NANODBC_CALL(SQLGetStmtAttr, rc,
            stmt_.native_stmt_handle()
            , SQL_ATTR_ROW_NUMBER
            , &pos
            , SQL_IS_UINTEGER
            , 0);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
        return pos;
    }

    bool end() const
    {
        return (position() > rows());
    }

    bool is_null(short column, long row) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        bound_column& col = bound_columns_[column];
        if(row >= rows())
            throw index_range_error();
        return col.cbdata_[row] == SQL_NULL_DATA;
    }

    std::string column_name(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        return bound_columns_[column].name_;
    }

    template<class T>
    T get(short column, long row = 0) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        if(is_null(column, row))
            throw null_access_error();
        bound_column& col = bound_columns_[column];

        switch(col.ctype_)
        {
            case SQL_C_SSHORT: return (T)*(short*)(col.pdata_ + row * col.clen_);
            case SQL_C_USHORT: return (T)*(unsigned short*)(col.pdata_ + row * col.clen_);
            case SQL_C_SLONG: return (T)*(long*)(col.pdata_ + row * col.clen_);
            case SQL_C_ULONG: return (T)*(unsigned long*)(col.pdata_ + row * col.clen_);
            case SQL_C_FLOAT: return (T)*(float*)(col.pdata_ + row * col.clen_);
            case SQL_C_DOUBLE: return (T)*(double*)(col.pdata_ + row * col.clen_);
            case SQL_C_CHAR: if (!col.blob_) return convert<T>((col.pdata_ + row * col.clen_));
        }
        throw type_incompatible_error();
    }

private:
    result_impl(const result_impl&); // not defined
    result_impl& operator=(const result_impl&); // not defined

    void before_move() throw()
    {
        for(short i = 0; i < bound_columns_size_; ++i)
        {
            bound_column& col = bound_columns_[i];
            for(long j = 0; j < col.rowset_size_; ++j)
                col.cbdata_[j] = 0;
            if(col.blob_ && col.pdata_)
                release_bound_resources(i);
        }
    }

    void release_bound_resources(short column) throw()
    {
        assert(column < bound_columns_size_);
        bound_column& col = bound_columns_[column];
        delete[] col.pdata_;
        col.pdata_ = 0;
        col.clen_ = 0;
    }

    bool fetch(long rows, SQLUSMALLINT orientation)
    {
        before_move();
        RETCODE rc;
        NANODBC_CALL(SQLFetchScroll, rc, stmt_.native_stmt_handle(), orientation, rows);
        if (rc == SQL_NO_DATA)
            return false;
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
        return true;
    }

    void auto_bind()
    {
        SQLSMALLINT n_columns = 0;
        RETCODE rc;
        NANODBC_CALL(SQLNumResultCols, rc, stmt_.native_stmt_handle(), &n_columns);

        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
        if(n_columns < 1)
            return;

        assert(!bound_columns_);
        assert(!bound_columns_size_);
        bound_columns_ = new bound_column[n_columns];
        bound_columns_size_ = n_columns;

        SQLCHAR column_name[1024];
        SQLSMALLINT sqltype, scale, nullable, len;
        SQLULEN sqlsize;

        for(SQLSMALLINT i = 0; i < n_columns; ++i)
        {
            RETCODE rc;
            NANODBC_CALL(SQLDescribeCol, rc,
                stmt_.native_stmt_handle()
                , i + 1
                , column_name
                , sizeof(column_name)
                , &len
                , &sqltype
                , &sqlsize
                , &scale
                , &nullable);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);

            bound_column& col = bound_columns_[i];
            col.name_ = reinterpret_cast<char*>(column_name);
            col.sqltype_ = sqltype;
            col.sqlsize_ = sqlsize;
            col.scale_ = scale;

            switch(col.sqltype_)
            {
                case SQL_BIT:
                case SQL_TINYINT:
                case SQL_SMALLINT:
                case SQL_INTEGER:
                    col.ctype_ = SQL_C_LONG;
                    col.clen_ = 4;
                    break;
                case SQL_DOUBLE:
                case SQL_FLOAT:
                case SQL_NUMERIC:
                case SQL_DECIMAL:
                case SQL_REAL:
                    col.ctype_ = SQL_C_DOUBLE;
                    col.clen_ = 8;
                    break;
                case SQL_DATE:
                case SQL_TYPE_DATE:
                    col.ctype_ = SQL_C_DATE;
                    col.clen_ = sizeof(date_type);
                    break;
                case SQL_TIMESTAMP:
                case SQL_TYPE_TIMESTAMP:
                    col.ctype_ = SQL_C_TIMESTAMP;
                    col.clen_ = sizeof(timestamp_type);
                    break;
                case SQL_CHAR:
                case SQL_VARCHAR:
                    col.ctype_ = SQL_C_CHAR;
                    col.clen_ = col.sqlsize_ + 1;
                    break;
                case SQL_LONGVARCHAR:
                    col.ctype_ = SQL_C_CHAR;
                    col.blob_ = true;
                    col.clen_ = 0;
                    break;
                case SQL_BINARY:
                case SQL_VARBINARY:
                    col.ctype_ = SQL_C_BINARY;
                    col.clen_ = col.sqlsize_ + 1;
                    break;
                case SQL_LONGVARBINARY:
                    col.ctype_ = SQL_C_BINARY;
                    col.blob_ = true;
                    col.clen_ = 0;
                    break;
                default:
                    col.ctype_ = sql_type_info<std::string>::ctype;
                    col.clen_ = 128;
                    break;
            }
        }

        for(SQLSMALLINT i = 0; i < n_columns; ++i)
        {
            bound_column& col = bound_columns_[i];
            col.cbdata_ = new long[rowset_size_];
            if(col.blob_)
            {
                NANODBC_CALL(SQLBindCol, rc, stmt_.native_stmt_handle(), i + 1, col.ctype_, 0, 0, col.cbdata_);
                if(!success(rc))
                    NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
            }
            else
            {
                col.rowset_size_ = rowset_size_;
                col.pdata_ = new char[rowset_size_ * col.clen_];
                NANODBC_CALL(SQLBindCol, rc, stmt_.native_stmt_handle(), i + 1, col.ctype_, col.pdata_, col.clen_, col.cbdata_);
                if(!success(rc))
                    NANODBC_THROW_DATABASE_ERROR(stmt_.native_stmt_handle(), SQL_HANDLE_STMT);
            }
        }
    }   

private:
    statement stmt_;
    const long rowset_size_;
    long row_count_;
    bound_column* bound_columns_;
    short bound_columns_size_;
};

template<>
inline std::string result::result_impl::get<std::string>(short column, long row) const
{
    if(column >= bound_columns_size_)
        throw index_range_error();
    if(is_null(column, row))
        throw null_access_error();
    bound_column& col = bound_columns_[column];

    char buffer[1024]; // #T get max length from describe col
    switch(col.ctype_)
    {
        case SQL_C_CHAR:
        case SQL_C_GUID:
        case SQL_C_BINARY:
            if(col.blob_)
                throw std::runtime_error("blob not implemented yet"); // #T implement load_blob(column);
            return (col.pdata_ + row * col.clen_);

        case SQL_C_LONG:
            if(std::snprintf(buffer, sizeof(buffer), "%ld", *(long*)(col.pdata_ + row * col.clen_)) != 1)
                throw type_incompatible_error();
            return buffer;

        case SQL_C_DOUBLE:
            if(std::snprintf(buffer, sizeof(buffer), "%lf", *(double*)(col.pdata_ + row * col.clen_)) != 1)
                throw type_incompatible_error();
            return buffer;

        case SQL_C_DATE:
            throw std::runtime_error("date not implemented yet"); // #T implement date conversion

        case SQL_C_TIMESTAMP:
            throw std::runtime_error("timestamp not implemented yet"); // #T implement timestamp conversion
    }
    throw type_incompatible_error();
}

///////////////////////////////////////////////////////////////////////////////
// Pimpl Forwards
///////////////////////////////////////////////////////////////////////////////

connection::connection()
: impl_(new connection_impl())
{

}

connection::connection(const connection& rhs)
: impl_(rhs.impl_)
{

}

connection& connection::operator=(connection rhs)
{
    swap(rhs);
    return *this;
}

void connection::swap(connection& rhs) throw()
{
    using std::swap;
    swap(impl_, rhs.impl_);
}

connection::connection(const std::string& dsn, const std::string& user, const std::string& pass, long timeout)
: impl_(new connection_impl(dsn, user, pass, timeout))
{

}

connection::connection(const std::string& connection_string, long timeout)
: impl_(new connection_impl(connection_string, timeout))
{

}

connection::~connection() throw()
{

}

void connection::connect(const std::string& dsn, const std::string& user, const std::string& pass, long timeout)
{
    impl_->connect(dsn, user, pass, timeout);
}

void connection::connect(const std::string& connection_string, long timeout)
{
    impl_->connect(connection_string, timeout);
}

bool connection::connected() const
{
    return impl_->connected();
}

void connection::disconnect() throw()
{
    impl_->disconnect();
}

std::size_t connection::transactions() const
{
    return impl_->transactions();
}

HDBC connection::native_dbc_handle() const
{
    return impl_->native_dbc_handle();
}

HDBC connection::native_env_handle() const
{
    return impl_->native_env_handle();
}

std::string connection::driver_name() const
{
    return impl_->driver_name();
}

std::size_t connection::ref_transaction()
{
    return impl_->ref_transaction();
}

std::size_t connection::unref_transaction()
{
    return impl_->unref_transaction();
}

bool connection::rollback() const
{
    return impl_->rollback();
}

void connection::rollback(bool onoff)
{
    impl_->rollback(onoff);
}

transaction::transaction(const class connection& conn)
: impl_(new transaction_impl(conn))
{

}

transaction::transaction(const transaction& rhs)
: impl_(rhs.impl_)
{

}

transaction& transaction::operator=(transaction rhs)
{
    swap(rhs);
    return *this;
}

void transaction::swap(transaction& rhs) throw()
{
    using std::swap;
    swap(impl_, rhs.impl_);
}

transaction::~transaction() throw()
{

}

void transaction::commit()
{
    impl_->commit();
}

void transaction::rollback() throw()
{
    impl_->rollback();
}

class connection& transaction::connection()
{
    return impl_->connection();
}

const class connection& transaction::connection() const
{
    return impl_->connection();
}

transaction::operator class connection&()
{
    return impl_->connection();
}

transaction::operator const class connection&() const
{
    return impl_->connection();
}

statement::statement()
: impl_(new statement_impl())
{

}

statement::statement(connection& conn, const std::string& stmt)
: impl_(new statement_impl(conn, stmt))
{

}

statement::statement(const statement& rhs)
: impl_(rhs.impl_)
{

}

statement& statement::operator=(statement rhs)
{
    swap(rhs);
    return *this;
}

void statement::swap(statement& rhs) throw()
{
    using std::swap;
    swap(impl_, rhs.impl_);
}

statement::~statement() throw()
{

}

void statement::open(connection& conn)
{
    impl_->open(conn);
}

bool statement::open() const
{
    return impl_->open();
}

HDBC statement::native_stmt_handle() const
{
    return impl_->native_stmt_handle();
}

void statement::close()
{
    impl_->close();
}

void statement::cancel()
{
    impl_->cancel();
}

void statement::prepare(connection& conn, const std::string& stmt)
{
    impl_->prepare(conn, stmt);
}

result statement::execute_direct(connection& conn, const std::string& query, long batch_operations)
{
    return impl_->execute_direct(conn, query, batch_operations, *this);
}

result statement::execute(long batch_operations)
{
    return impl_->execute(batch_operations, *this);
}

long statement::affected_rows() const
{
    return impl_->affected_rows();
}

void statement::reset_parameters() throw()
{
    impl_->reset_parameters();
}

template<class T>
void statement::bind_parameter(long param, const T& value)
{
    impl_->bind_parameter(param, value);
}
template void statement::bind_parameter(long, const short&);
template void statement::bind_parameter(long, const unsigned short&);
template void statement::bind_parameter(long, const long&);
template void statement::bind_parameter(long, const unsigned long&);
template void statement::bind_parameter(long, const int&);
template void statement::bind_parameter(long, const unsigned int&);
template void statement::bind_parameter(long, const float&);
template void statement::bind_parameter(long, const double&);
template void statement::bind_parameter(long, const std::string&);

void statement::bind_parameter(
    long param
    , SQLSMALLINT ctype
    , SQLSMALLINT sqltype
    , char* data
    , std::size_t element_size
    , std::size_t elements
    , bool take_ownership)
{
    impl_->bind_parameter(param, ctype, sqltype, data, element_size, elements, take_ownership);
}

unsigned long statement::parameter_column_size(long param) const
{
    return impl_->parameter_column_size(param);
}

result::result()
: impl_()
{

}

result::~result() throw()
{

}

result::result(statement stmt, long rowset_size)
: impl_(new result_impl(stmt, rowset_size))
{

}

result::result(const result& rhs)
: impl_(rhs.impl_)
{

}

result& result::operator=(result rhs)
{
    swap(rhs);
    return *this;
}

void result::swap(result& rhs) throw()
{
    using std::swap;
    swap(impl_, rhs.impl_);
}

HDBC result::native_stmt_handle() const
{
    return impl_->native_stmt_handle();
}

long result::rowset_size() const
{
    return impl_->rowset_size();
}

long result::affected_rows() const
{
    return impl_->affected_rows();
}

long result::rows() const
{
    return impl_->rows();
}

short result::columns() const
{
    return impl_->columns();
}

bool result::first()
{
    return impl_->first();
}

bool result::last()
{
    return impl_->last();
}

bool result::next()
{
    return impl_->next();
}

bool result::prior()
{
    return impl_->prior();
}

bool result::move(long row)
{
    return impl_->move(row);
}

bool result::skip(long rows)
{
    return impl_->skip(rows);
}

long result::position() const
{
    return impl_->position();
}

bool result::end() const
{
    return impl_->end();
}

bool result::is_null(short column, long row) const
{
    return impl_->is_null(column, row);
}

std::string result::column_name(short column) const
{
    return impl_->column_name(column);
}

template<class T>
T result::get(short column, long row) const
{
    return impl_->get<T>(column, row);
}
template short result::get(short, long) const;
template unsigned short result::get(short, long) const;
template long result::get(short, long) const;
template unsigned long result::get(short, long) const;
template int result::get(short, long) const;
template unsigned int result::get(short, long) const;
template float result::get(short, long) const;
template double result::get(short, long) const;
template std::string result::get(short, long) const;

} // namespace nanodbc

#undef NANODBC_THROW_DATABASE_ERROR
#undef NANODBC_STRINGIZE
#undef NANODBC_STRINGIZE_I
#undef NANODBC_CALL
