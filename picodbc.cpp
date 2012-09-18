//! \file picodbc.cpp Implementation details.

#include "picodbc.h"

#include <algorithm> // std::copy()
#include <cassert> // assert()
#include <vector> // std::vector

#define PICODBC_STRINGIZE_I(text) #text
#define PICODBC_STRINGIZE(text) PICODBC_STRINGIZE_I(text)
#define PICODBC_THROW_DATABASE_ERROR(handle, handle_type) throw database_error(handle, handle_type, __FILE__ ":" PICODBC_STRINGIZE(__LINE__) ": ")

#ifdef PICODBC_ODBC_API_DEBUG
    #include <iostream>
    #define PICODBC_CALL(FUNC, RC, ...)                                                            \
        do {                                                                                       \
            std::cerr << __FILE__ << ":" PICODBC_STRINGIZE(__LINE__) << " " << #FUNC << std::endl; \
            RC = FUNC(__VA_ARGS__);                                                                \
        } while(false)                                                                             \
        /**/
#else
    #define PICODBC_CALL(FUNC, RC, ...) RC = FUNC(__VA_ARGS__)
#endif

namespace picodbc
{

namespace detail
{
    // easy way to check if a return code signifies success.
    inline bool success(RETCODE rc)
    {
        return rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO;
    }

    // Tests if the given return data indicates null data.
    inline bool data_is_null(SQLLEN cbdata)
    {
        return (cbdata == SQL_NULL_DATA);
    }

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
        PICODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        PICODBC_CALL(SQLSetEnvAttr, rc, env, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, 0);
        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        PICODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env, &conn);   
        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);
    }

    const char* const sql_type_info<short>::format = "%hd";
    const char* const sql_type_info<unsigned short>::format = "%hu";
    const char* const sql_type_info<long>::format = "%ld";
    const char* const sql_type_info<unsigned long>::format = "%lu";
    const char* const sql_type_info<int>::format = "%d";
    const char* const sql_type_info<unsigned int>::format = "%u";
    const char* const sql_type_info<float>::format = "%f";
    const char* const sql_type_info<double>::format = "%ld";
    const char* const sql_type_info<std::string>::format = "%s";
} // namespace detail

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
: std::runtime_error(info + detail::last_error(handle, handle_type)) { }

const char* database_error::what() const throw()
{
    return std::runtime_error::what();
}

connection::connection()
: env_(0)
, conn_(0)
, connected_(false)
, transactions_(0)
, rollback_(false)
{
    detail::allocate_handle(env_, conn_);
}

connection::connection(const std::string& dsn, const std::string& user, const std::string& pass, int timeout)
: env_(0)
, conn_(0)
, connected_(false)
, transactions_(0)
, rollback_(false)
{
    detail::allocate_handle(env_, conn_);
    connect(dsn, user, pass, timeout);
}

connection::connection(const std::string& connection_string, int timeout)
: env_(0)
, conn_(0)
, connected_(false)
, transactions_(0)
, rollback_(false)
{
    detail::allocate_handle(env_, conn_);
    connect(connection_string, timeout);
}

connection::~connection()
{
    disconnect();
    RETCODE rc;
    PICODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
    PICODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_ENV, env_);
}

void connection::connect(const std::string& dsn, const std::string& user, const std::string& pass, int timeout)
{
    disconnect();
    RETCODE rc;
    PICODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
    PICODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
    PICODBC_CALL(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, reinterpret_cast<SQLPOINTER*>(timeout), 0);
    PICODBC_CALL(SQLConnect, rc,
        conn_
        , (SQLCHAR*)dsn.c_str(), SQL_NTS
        , user.empty() ? (SQLCHAR*)user.c_str() : 0, SQL_NTS
        , pass.empty() ? (SQLCHAR*)pass.c_str() : 0, SQL_NTS);
    connected_ = detail::success(rc);
    if (!connected_)
        PICODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
}

void connection::connect(const std::string& connection_string, int timeout)
{
    disconnect();
    RETCODE rc;
    PICODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
    PICODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
    SQLCHAR dsn[1024];
    SQLSMALLINT dsn_size = 0;
    PICODBC_CALL(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, reinterpret_cast<SQLPOINTER*>(timeout), 0);
    PICODBC_CALL(SQLDriverConnect, rc,
        conn_
        , 0
        , (SQLCHAR*)connection_string.c_str(), SQL_NTS
        , dsn, sizeof(dsn)
        , &dsn_size
        , SQL_DRIVER_NOPROMPT);
    connected_ = detail::success(rc);
    if (!connected_)
        PICODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
}

bool connection::connected() const
{
    return connected_;
}

void connection::disconnect()
{
    if(connected())
    {
        SQLDisconnect(conn_);
    }
    connected_ = false;
}

std::size_t connection::transactions() const
{
    return transactions_;
}

HDBC connection::native_dbc_handle() const
{
    return conn_;
}

HDBC connection::native_evn_handle() const
{
    return env_;
}

std::string connection::driver_name() const
{
    char name[1024];
    SQLSMALLINT length;
    RETCODE rc;
    PICODBC_CALL(SQLGetInfo, rc, conn_, SQL_DRIVER_NAME, name, sizeof(name), &length);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
    return name;
}

transaction::transaction(connection& conn)
: conn_(conn)
, committed_(false)
{
    if(conn_.transactions_ == 0 && conn_.connected())
    {
        RETCODE rc;
        PICODBC_CALL(SQLSetConnectAttr, rc,
            conn_.native_dbc_handle()
            , SQL_ATTR_AUTOCOMMIT
            , static_cast<SQLPOINTER>(SQL_AUTOCOMMIT_OFF)
            , SQL_IS_UINTEGER);
        if (!detail::success(rc))
            PICODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
    }
    ++conn_.transactions_;
}

transaction::~transaction()
{
    if(!committed_)
    {
        conn_.rollback_ = true;
        --conn_.transactions_;
    }

    if(conn_.transactions_ == 0 && conn_.rollback_ && conn_.connected())
    {
        RETCODE rc;
        PICODBC_CALL(SQLEndTran, rc, SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_ROLLBACK);
        if (!detail::success(rc))
            throw database_error(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
        conn_.rollback_ = false;
        PICODBC_CALL(SQLSetConnectAttr, rc, 
            conn_.native_dbc_handle()
            , SQL_ATTR_AUTOCOMMIT
            , reinterpret_cast<SQLPOINTER>(SQL_AUTOCOMMIT_ON)
            , SQL_IS_UINTEGER);
        if (!detail::success(rc))
            PICODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
    }
}

void transaction::commit() throw()
{
    if(committed_)
        return;
    committed_ = true;
    if((--conn_.transactions_) == 0 && conn_.connected())
    {
        RETCODE rc;
        PICODBC_CALL(SQLEndTran, rc, SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_COMMIT);
    }
}

void transaction::rollback() throw()
{
    if(committed_)
        return;
    conn_.rollback_ = true;
}

namespace detail
{

class bound_parameter
{
public:
    ~bound_parameter()
    {

    }

private:
    bound_parameter(HSTMT stmt, long param)
    : stmt_(stmt)
    , param_(param)
    {

    }

    // #T need to refactor as shared pimpl
    bound_parameter(const bound_parameter& rhs)
    : stmt_(rhs.stmt_)
    , param_(rhs.param_)
    {

    }

    // #T need to refactor as shared pimpl
    bound_parameter& operator=(bound_parameter rhs)
    {
        swap(rhs);
        return *this;
    }

    // #T need to refactor as shared pimpl
    void swap(bound_parameter& rhs)
    {
        using std::swap;
        swap(stmt_, rhs.stmt_);
        swap(param_, rhs.param_);
    }

    void set_value(SQLSMALLINT ctype, SQLSMALLINT sqltype, char* value, std::size_t value_size)
    {
        using std::copy;
        copy(value, value + value_size, value_buffer_);

        SQLLEN str_len_or_ind_ptr = 0;
        RETCODE rc;
        PICODBC_CALL(SQLBindParameter, rc, 
            stmt_
            , param_ + 1
            , SQL_PARAM_INPUT
            , ctype
            , sqltype
            , 0
            , 0
            , (SQLPOINTER)value_buffer_
            , 0
            , &str_len_or_ind_ptr);
    }

    void set_string(const std::string& str)
    {
        string_buffer_ = str;
        string_buffer_len_ = SQL_NTS;
        RETCODE rc;
        PICODBC_CALL(SQLBindParameter, rc, 
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
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

private:
    friend void statement_bind_parameter_value(
        statement* me
        , long param
        , SQLSMALLINT ctype
        , SQLSMALLINT sqltype
        , char* value
        , std::size_t value_size);

    friend void statement_bind_parameter_string(
        statement* me
        , long param
        , const std::string& string);

private:
    HSTMT stmt_;
    long param_;
    char value_buffer_[512];
    std::string string_buffer_;
    SQLLEN string_buffer_len_;
};

void statement_bind_parameter_value(
    statement* me
    , long param
    , SQLSMALLINT ctype
    , SQLSMALLINT sqltype
    , char* value
    , std::size_t value_size)
{
    if(!me->bound_parameters_.count(param))
        me->bound_parameters_[param] = new class bound_parameter(me->stmt_, param);
    me->bound_parameters_[param]->set_value(ctype, sqltype, value, value_size);
}

void statement_bind_parameter_string(
    statement* me
    , long param
    , const std::string& string)
{
    if(!me->bound_parameters_.count(param))
        me->bound_parameters_[param] = new class bound_parameter(me->stmt_, param);
    me->bound_parameters_[param]->set_string(string);
}

class result_impl
{
private:
    typedef std::vector<SQLLEN> indicator_type;
    typedef std::map<short, indicator_type> indicators_type;

public:
    ~result_impl()
    {
        before_move();
        delete[] bound_columns_;
    }

    HDBC native_stmt_handle() const
    {
        return stmt_;
    }

    unsigned long rowset_size() const
    {
        return rowset_size_;
    }

    long affected_rows() const
    {
        SQLLEN rows;
        RETCODE rc;
        PICODBC_CALL(SQLRowCount, rc, stmt_, &rows);
        if (!detail::success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
        PICODBC_CALL(SQLNumResultCols, rc, stmt_, &cols);
        if (!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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

    bool move(unsigned long row)
    {
        return fetch(row, SQL_FETCH_ABSOLUTE);
    }

    bool skip(unsigned long rows)
    {
        return fetch(rows, SQL_FETCH_RELATIVE);
    }

    unsigned long position() const
    {
        SQLULEN pos;
        RETCODE rc;
        PICODBC_CALL(SQLGetStmtAttr, rc,
            stmt_
            , SQL_ATTR_ROW_NUMBER
            , &pos
            , SQL_IS_UINTEGER
            , 0);
        if (!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return pos;
    }

    bool end() const
    {
        return (position() > static_cast<unsigned long>(rows()));
    }

    bool is_null(short column, unsigned long row) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        bound_column& col = bound_columns_[column];
        if(row >= rows())
            throw index_range_error();
        return data_is_null(col.cbdata_[row]);
    }

    std::string column_name(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        return bound_columns_[column].name_;
    }

private:
    result_impl(const result_impl&); // not defined
    result_impl& operator=(const result_impl&); // not defined

    result_impl(HDBC stmt, unsigned long rowset_size)
    : stmt_(stmt)
    , rowset_size_(rowset_size)
    , row_count_(0)
    , indicators_()
    , bound_columns_(0)
    , bound_columns_size_(0)
    {
        RETCODE rc;
        PICODBC_CALL(SQLSetStmtAttr, rc, stmt, SQL_ATTR_ROW_ARRAY_SIZE, (SQLPOINTER)rowset_size_, 0);
        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt, SQL_HANDLE_STMT);

        PICODBC_CALL(SQLSetStmtAttr, rc, stmt, SQL_ATTR_ROWS_FETCHED_PTR, &row_count_, 0);
        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt, SQL_HANDLE_STMT);

        auto_bind();
    }

    void before_move()
    {
        for(short i = 0; i < bound_columns_size_; ++i)
        {
            bound_column& col = bound_columns_[i];
            for(unsigned long j = 0; j < col.rowset_size_; ++j)
                col.cbdata_[j] = 0;
            if(col.blob_ && col.pdata_)
                release_bound_resources(i);
        }
    }

    void release_bound_resources(short column)
    {
        throw std::runtime_error("SHOULDN'T GET HERE!");
        if(column >= bound_columns_size_)
            throw index_range_error();

        bound_column& col = bound_columns_[column];
        delete[] col.pdata_;

        col.pdata_ = 0;
        col.clen_ = 0;
    }

    bool fetch(unsigned long rows, SQLUSMALLINT orientation)
    {
        before_move();
        RETCODE rc;
        PICODBC_CALL(SQLFetchScroll, rc, stmt_, orientation, rows);
        if (rc == SQL_NO_DATA)
            return false;
        if (!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return true;
    }

    void auto_bind()
    {
        SQLSMALLINT n_columns = 0;
        RETCODE rc;
        PICODBC_CALL(SQLNumResultCols, rc, stmt_, &n_columns);

        if(!success(rc))
            PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
            PICODBC_CALL(SQLDescribeCol, rc,
                stmt_
                , i + 1
                , column_name
                , sizeof(column_name)
                , &len
                , &sqltype
                , &sqlsize
                , &scale
                , &nullable);

            if(!success(rc))
                PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

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
                PICODBC_CALL(SQLBindCol, rc, stmt_, i + 1, col.ctype_, 0, 0, col.cbdata_);
            }
            else
            {
                col.rowset_size_ = rowset_size_;
                col.pdata_ = new char[rowset_size_ * col.clen_];
                PICODBC_CALL(SQLBindCol, rc, stmt_, i + 1, col.ctype_, col.pdata_, col.clen_, col.cbdata_);
            }
            if(!success(rc))
                PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        }
    }   

private:
    friend class result;
    friend bound_column& result_impl_get_bound_column(result_impl_ptr me, short column, unsigned long row);

private:
    const HDBC stmt_;
    const unsigned long rowset_size_;
    unsigned long row_count_;
    indicators_type indicators_;
    bound_column* bound_columns_;
    std::size_t bound_columns_size_;
};

bound_column& result_impl_get_bound_column(result_impl_ptr me, short column, unsigned long row)
{
    if(column >= me->bound_columns_size_)
        throw index_range_error();
    if(me->is_null(column, row))
        throw null_access_error();
    return me->bound_columns_[column];
}

} // namespace detail

result::result()
: impl_()
{

}

result::~result()
{

}

result::result(HDBC stmt, unsigned long rowset_size)
: impl_(new detail::result_impl_ptr::element_type(stmt, rowset_size))
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

unsigned long result::rowset_size() const
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

bool result::move(unsigned long row)
{
    return impl_->move(row);
}

bool result::skip(unsigned long rows)
{
    return impl_->skip(rows);
}

unsigned long result::position() const
{
    return impl_->position();
}

//! \brief Returns true if there are no more results in the current result set.
//! \throws database_error
bool result::end() const
{
    return impl_->end();
}

bool result::is_null(short column, unsigned long row) const
{
    return impl_->is_null(column, row);
}

std::string result::column_name(short column) const
{
    return impl_->column_name(column);
}

statement::statement()
: stmt_(0)
, open_(false)
, bound_parameters_()
{

}

statement::statement(connection& conn, const std::string& stmt)
: stmt_(0)
, open_(false)
, bound_parameters_()
{
    prepare(conn, stmt);
}

statement::~statement()
{
    close();
}

void statement::open(connection& conn)
{
    close();
    RETCODE rc;
    PICODBC_CALL(SQLAllocHandle, rc, SQL_HANDLE_STMT, conn.native_dbc_handle(), &stmt_);
    open_ = detail::success(rc);
    if (!open_)
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
}

bool statement::open() const
{
    return open_;
}

HDBC statement::native_stmt_handle() const
{
    return stmt_;
}

void statement::close()
{
    if(!open())
        return;
    RETCODE rc;
    PICODBC_CALL(SQLCancel, rc, stmt_);
    PICODBC_CALL(SQLCloseCursor, rc, stmt_);
    reset_parameters();
    PICODBC_CALL(SQLFreeHandle, rc, SQL_HANDLE_STMT, stmt_);
    open_ = false;
    stmt_ = 0;
}

void statement::cancel()
{
    RETCODE rc;
    PICODBC_CALL(SQLCancel, rc, stmt_);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
}

void statement::prepare(connection& conn, const std::string& stmt)
{
    open(conn);
    RETCODE rc;
    PICODBC_CALL(SQLPrepare, rc, stmt_, (SQLCHAR*)stmt.c_str(), SQL_NTS);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
}

result statement::execute_direct(connection& conn, const std::string& query, unsigned long rowset_size)
{
    open(conn);
    RETCODE rc;
    PICODBC_CALL(SQLExecDirect, rc, stmt_, (SQLCHAR*)query.c_str(), SQL_NTS);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    return result(stmt_, rowset_size);
}

result statement::execute(unsigned long rowset_size)
{
    RETCODE rc;
    PICODBC_CALL(SQLExecute, rc, stmt_);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    return result(stmt_, rowset_size);
}

long statement::affected_rows() const
{
    SQLLEN rows;
    RETCODE rc;
    PICODBC_CALL(SQLRowCount, rc, stmt_, &rows);
    if (!detail::success(rc))
        PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    return rows;
}

void statement::reset_parameters()
{
    RETCODE rc;
    PICODBC_CALL(SQLFreeStmt, rc, stmt_, SQL_RESET_PARAMS);
    for(bound_parameters_type::iterator i = bound_parameters_.begin(), end = bound_parameters_.end(); i != end; ++i)
        delete i->second;
    bound_parameters_.clear();
}

} // namespace picodbc

#undef PICODBC_THROW_DATABASE_ERROR
#undef PICODBC_STRINGIZE
#undef PICODBC_STRINGIZE_I
#undef PICODBC_CALL
