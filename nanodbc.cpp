//! \file nanodbc.cpp Implementation details.

#include "nanodbc.h"

#include <algorithm>
#include <cassert>
#include <clocale>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <map>

#if defined(_MSC_VER) && _MSC_VER <= 1500
    // silence spurious Visual C++ 2005 warnings 
    #pragma warning(disable:4244)
    #pragma warning(disable:4312)
#endif

#ifdef __APPLE__
    // silence spurious OS X deprecation warnings
    #define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_6
#endif

#include <sql.h>
#include <sqlext.h>

#ifdef _WIN32
    #include <windows.h>
#endif

///////////////////////////////////////////////////////////////////////////////
// Unicode Support
///////////////////////////////////////////////////////////////////////////////
#if defined(_MSC_VER) && _MSC_VER <= 1400
    #ifdef NANODBC_USE_UNICODE
        #define NANODBC_TEXT(s) L ## s
        #define NANODBC_SSCANF std::swscanf
        #define NANODBC_SNPRINTF swprintf
        #define NANODBC_STRFTIME std::wcsftime
        #define NANODBC_UNICODE(f) f ## W
        #define NANODBC_SQLCHAR SQLWCHAR
    #else
        #define NANODBC_TEXT(s) s
        #define NANODBC_SSCANF std::sscanf
        #define NANODBC_SNPRINTF _snprintf
        #define NANODBC_STRFTIME std::strftime
        #define NANODBC_UNICODE(f) f
        #define NANODBC_SQLCHAR SQLCHAR
    #endif
#else
    #ifdef NANODBC_USE_UNICODE
        #define NANODBC_TEXT(s) L ## s
        #define NANODBC_SSCANF std::swscanf
        #define NANODBC_SNPRINTF swprintf
        #define NANODBC_STRFTIME std::wcsftime
        #define NANODBC_UNICODE(f) f ## W
        #define NANODBC_SQLCHAR SQLWCHAR
    #else
        #define NANODBC_TEXT(s) s
        #define NANODBC_SSCANF std::sscanf
        #define NANODBC_SNPRINTF std::snprintf
        #define NANODBC_STRFTIME std::strftime
        #define NANODBC_UNICODE(f) f
        #define NANODBC_SQLCHAR SQLCHAR
    #endif
#endif

///////////////////////////////////////////////////////////////////////////////
// ODBC API Interface
///////////////////////////////////////////////////////////////////////////////

// By making all calls to ODBC functions through this macro, we can easily get
// runtime debugging information of which ODBC functions are being called,
// in what order, and with what parameters by defining NANODBC_ODBC_API_DEBUG.

#ifdef NANODBC_ODBC_API_DEBUG
    #include <iostream>
    #define NANODBC_CALL_RC(FUNC, RC, ...)                                    \
        do {                                                                  \
            std::cerr << __FILE__ ":" NANODBC_STRINGIZE(__LINE__) " "         \
                NANODBC_STRINGIZE(FUNC) "(" #__VA_ARGS__ ")" << std::endl;    \
            RC = FUNC(__VA_ARGS__);                                           \
        } while(false)                                                        \
        /**/
    #define NANODBC_CALL(FUNC, ...)                                           \
        do {                                                                  \
            std::cerr << __FILE__ ":" NANODBC_STRINGIZE(__LINE__) " "         \
                NANODBC_STRINGIZE(FUNC) "(" #__VA_ARGS__ ")" << std::endl;    \
            FUNC(__VA_ARGS__);                                                \
        } while(false)                                                        \
        /**/
#else
    #define NANODBC_CALL_RC(FUNC, RC, ...) RC = FUNC(__VA_ARGS__)
    #define NANODBC_CALL(FUNC, ...) FUNC(__VA_ARGS__)
#endif

///////////////////////////////////////////////////////////////////////////////
// Error and Exception Handling
///////////////////////////////////////////////////////////////////////////////

namespace
{
    // Easy way to check if a return code signifies success.
    inline bool success(RETCODE rc)
    {
        return rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO;
    }

    // Attempts to get the last ODBC error as a string.
    inline std::string last_error(SQLHANDLE handle, SQLSMALLINT handle_type)
    {
        SQLCHAR sql_state[6];
        SQLCHAR sql_message[SQL_MAX_MESSAGE_LENGTH];
        SQLINTEGER native_error;
        SQLSMALLINT total_bytes;
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLGetDiagRec
            , rc
            , handle_type
            , handle
            , 1
            , (SQLCHAR*)sql_state
            , &native_error
            , (SQLCHAR*)sql_message
            , sizeof(sql_message)
            , &total_bytes);
        if(success(rc))
        {
            std::string error = reinterpret_cast<std::string::value_type*>(sql_message);
            std::string status = reinterpret_cast<std::string::value_type*>(sql_state);
            return status + ": " + error;
        }
        return "Unknown Error: SQLGetDiagRec() call failed";
    }
} // namespace

namespace nanodbc
{
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

    programming_error::programming_error(const std::string& info)
    : std::runtime_error(info.c_str()) { }
    
    const char* programming_error::what() const throw()
    {
        return std::runtime_error::what();
    }

    database_error::database_error(void* handle, short handle_type, const std::string& info)
    : std::runtime_error(info + last_error(handle, handle_type)) { }

    const char* database_error::what() const throw()
    {
        return std::runtime_error::what();
    }
} // namespace nanodbc

// Throwing exceptions using NANODBC_THROW_DATABASE_ERROR enables file name
// and line numbers to be inserted into the error message. Useful for debugging.
#define NANODBC_STRINGIZE_I(text) #text
#define NANODBC_STRINGIZE(text) NANODBC_STRINGIZE_I(text)
#define NANODBC_THROW_DATABASE_ERROR(handle, handle_type)                     \
    throw nanodbc::database_error(                                            \
        handle                                                                \
        , handle_type                                                         \
        , __FILE__ ":" NANODBC_STRINGIZE(__LINE__) ": ")                      \
    /**/

///////////////////////////////////////////////////////////////////////////////
// Implementation Details
///////////////////////////////////////////////////////////////////////////////

namespace
{
    using namespace std; // if int64_t is in std namespace (in c++11)

    // A utility for calculating the ctype, sqltype, and format specifiers for the given type T.
    // I essentially create a lookup table based on the MSDN ODBC documentation.
    // See http://msdn.microsoft.com/en-us/library/windows/desktop/ms714556(v=vs.85).aspx for details.
    template<class T>
    struct sql_type_info { };

    template<>
    struct sql_type_info<char>
    { 
        static const SQLSMALLINT ctype = SQL_C_CHAR; 
        static const SQLSMALLINT sqltype = SQL_CHAR;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<wchar_t>
    { 
        static const SQLSMALLINT ctype = SQL_C_WCHAR; 
        static const SQLSMALLINT sqltype = SQL_WCHAR;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<short>
    {
        static const SQLSMALLINT ctype = SQL_C_SSHORT;
        static const SQLSMALLINT sqltype = SQL_SMALLINT; 
        static const nanodbc::string_type::value_type* const format;
    };

    template<>
    struct sql_type_info<unsigned short>
    { 
        static const SQLSMALLINT ctype = SQL_C_USHORT; 
        static const SQLSMALLINT sqltype = SQL_SMALLINT;    
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<int32_t>
    { 
        static const SQLSMALLINT ctype = SQL_C_SLONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<uint32_t>
    { 
        static const SQLSMALLINT ctype = SQL_C_ULONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<int64_t>
    {
        static const SQLSMALLINT ctype = SQL_C_SBIGINT;
        static const SQLSMALLINT sqltype = SQL_BIGINT;
        static const nanodbc::string_type::value_type* const format;
    };

    template<>
    struct sql_type_info<uint64_t>
    {
        static const SQLSMALLINT ctype = SQL_C_UBIGINT;
        static const SQLSMALLINT sqltype = SQL_BIGINT;
        static const nanodbc::string_type::value_type* const format;
    };

    template<>
    struct sql_type_info<float>
    { 
        static const SQLSMALLINT ctype = SQL_C_FLOAT; 
        static const SQLSMALLINT sqltype = SQL_FLOAT;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<double>
    { 
        static const SQLSMALLINT ctype = SQL_C_DOUBLE; 
        static const SQLSMALLINT sqltype = SQL_DOUBLE;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<std::string>
    { 
        static const SQLSMALLINT ctype = SQL_C_CHAR; 
        static const SQLSMALLINT sqltype = SQL_VARCHAR;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<std::wstring>
    { 
        static const SQLSMALLINT ctype = SQL_C_WCHAR; 
        static const SQLSMALLINT sqltype = SQL_WVARCHAR;
        static const nanodbc::string_type::value_type* const format; 
    };

    template<>
    struct sql_type_info<nanodbc::date>
    { 
        static const SQLSMALLINT ctype = SQL_C_DATE; 
        static const SQLSMALLINT sqltype = SQL_DATE;
    };

    template<>
    struct sql_type_info<nanodbc::timestamp>
    { 
        static const SQLSMALLINT ctype = SQL_C_TIMESTAMP; 
        static const SQLSMALLINT sqltype = SQL_TIMESTAMP;
    };

     const nanodbc::string_type::value_type* const sql_type_info<wchar_t>::format = NANODBC_TEXT("%lc");
     const nanodbc::string_type::value_type* const sql_type_info<short>::format = NANODBC_TEXT("%hd");
     const nanodbc::string_type::value_type* const sql_type_info<unsigned short>::format = NANODBC_TEXT("%hu");
     const nanodbc::string_type::value_type* const sql_type_info<int32_t>::format = NANODBC_TEXT("%ld");
     const nanodbc::string_type::value_type* const sql_type_info<uint32_t>::format = NANODBC_TEXT("%lu");
     const nanodbc::string_type::value_type* const sql_type_info<int64_t>::format = NANODBC_TEXT("%ld");
     const nanodbc::string_type::value_type* const sql_type_info<uint64_t>::format = NANODBC_TEXT("%lu");
     const nanodbc::string_type::value_type* const sql_type_info<float>::format = NANODBC_TEXT("%f");
     const nanodbc::string_type::value_type* const sql_type_info<double>::format = NANODBC_TEXT("%lf");

    // Converts the given string to the given type T.
    template<class T>
    inline T convert(const nanodbc::string_type& s)
    {
        T value;
        NANODBC_SSCANF(s.c_str(), sql_type_info<T>::format, &value);
        return value;
    }

    // Encapsulates resources needed for column binding.
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
        nanodbc::string_type name_;
        SQLSMALLINT sqltype_;
        SQLULEN sqlsize_;
        SQLSMALLINT scale_;
        SQLSMALLINT ctype_;
        SQLULEN clen_;
        bool blob_;
        long rowset_size_;
        nanodbc::null_type* cbdata_;
        char* pdata_;

    private:
        bound_column(const bound_column& rhs); // not defined
        bound_column& operator=(bound_column rhs); // not defined
    };

    // Allocates the native ODBC handles.
    inline void allocate_handle(SQLHENV& env, SQLHDBC& conn)
    {
        RETCODE rc;
        NANODBC_CALL_RC(SQLAllocHandle, rc, SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        NANODBC_CALL_RC(SQLSetEnvAttr, rc, env, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, SQL_IS_UINTEGER);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);

        NANODBC_CALL_RC(SQLAllocHandle, rc, SQL_HANDLE_DBC, env, &conn);   
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env, SQL_HANDLE_ENV);
    }
} // namespace

///////////////////////////////////////////////////////////////////////////////
// Private Implementation: connection
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

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

    connection_impl(const string_type& dsn, const string_type& user, const string_type& pass, long timeout)
    : env_(0)
    , conn_(0)
    , connected_(false)
    , transactions_(0)
    , rollback_(false)
    {
        allocate_handle(env_, conn_);
        connect(dsn, user, pass, timeout);
    }

    connection_impl(const string_type& connection_string, long timeout)
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
        NANODBC_CALL(SQLFreeHandle, SQL_HANDLE_DBC, conn_);
        NANODBC_CALL(SQLFreeHandle, SQL_HANDLE_ENV, env_);
    }

    void connect(const string_type& dsn, const string_type& user, const string_type& pass, long timeout)
    {
        disconnect();

        RETCODE rc;
        NANODBC_CALL_RC(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL_RC(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env_, SQL_HANDLE_ENV);

        NANODBC_CALL_RC(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, (SQLPOINTER)timeout, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL_RC(
            NANODBC_UNICODE(SQLConnect)
            , rc
            , conn_
            , (NANODBC_SQLCHAR*)dsn.c_str(), SQL_NTS
            , user.empty() ? (NANODBC_SQLCHAR*)user.c_str() : 0, SQL_NTS
            , pass.empty() ? (NANODBC_SQLCHAR*)pass.c_str() : 0, SQL_NTS);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        connected_ = success(rc);
    }

    void connect(const string_type& connection_string, long timeout)
    {
        disconnect();

        RETCODE rc;
        NANODBC_CALL_RC(SQLFreeHandle, rc, SQL_HANDLE_DBC, conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        NANODBC_CALL_RC(SQLAllocHandle, rc, SQL_HANDLE_DBC, env_, &conn_);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(env_, SQL_HANDLE_ENV);

        NANODBC_CALL_RC(SQLSetConnectAttr, rc, conn_, SQL_LOGIN_TIMEOUT, (SQLPOINTER)timeout, 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);

        string_type::value_type dsn[1024];
        SQLSMALLINT dsn_size = 0;
        NANODBC_CALL_RC(
            NANODBC_UNICODE(SQLDriverConnect)
            , rc
            , conn_
            , 0
            , (NANODBC_SQLCHAR*)connection_string.c_str(), SQL_NTS
            , (NANODBC_SQLCHAR*)dsn, sizeof(dsn)
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
            NANODBC_CALL(SQLDisconnect, conn_);
        }
        connected_ = false;
    }

    std::size_t transactions() const
    {
        return transactions_;
    }

    void* native_dbc_handle() const
    {
        return conn_;
    }

    void* native_env_handle() const
    {
        return env_;
    }

    string_type driver_name() const
    {
        string_type::value_type name[1024];
        SQLSMALLINT length;
        RETCODE rc;
        NANODBC_CALL_RC(
            NANODBC_UNICODE(SQLGetInfo)
            , rc
            , conn_
            , SQL_DRIVER_NAME
            , name
            , sizeof(name)
            , &length);
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

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Private Implementation: transaction
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

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
            NANODBC_CALL_RC(
                SQLSetConnectAttr
                , rc
                , conn_.native_dbc_handle()
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
            NANODBC_CALL(
                SQLEndTran
                , SQL_HANDLE_DBC
                , conn_.native_dbc_handle()
                , SQL_ROLLBACK);
            conn_.rollback(false);
            NANODBC_CALL(
                SQLSetConnectAttr
                , conn_.native_dbc_handle()
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
            NANODBC_CALL_RC(
                SQLEndTran
                , rc
                , SQL_HANDLE_DBC
                , conn_.native_dbc_handle()
                , SQL_COMMIT);
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

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Private Implementation: statement
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

class statement::statement_impl
{
public:
    statement_impl()
    : stmt_(0)
    , open_(false)
    , conn_()
    {

    }

    statement_impl(class connection& conn)
    : stmt_(0)
    , open_(false)
    , conn_()
    {
        open(conn);
    }

    statement_impl(class connection& conn, const string_type& query)
    : stmt_(0)
    , open_(false)
    , conn_()
    {
        prepare(conn, query);
    }

    ~statement_impl() throw()
    {
        if(open() && connected())
        {
            NANODBC_CALL(SQLCancel, stmt_);
            reset_parameters();
            NANODBC_CALL(SQLFreeHandle, SQL_HANDLE_STMT, stmt_);
        }
    }

    void open(class connection& conn)
    {
        close();
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLAllocHandle
            , rc
            , SQL_HANDLE_STMT
            , conn.native_dbc_handle()
            , &stmt_);
        open_ = success(rc);
        if (!open_)
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        conn_ = conn;
    }

    bool open() const
    {
        return open_;
    }

    bool connected() const
    {
        return conn_.connected();
    }

    const class connection& connection() const
    {
        return conn_;
    }

    class connection& connection()
    {
        return conn_;
    }

    void* native_statement_handle() const
    {
        return stmt_;
    }

    void close()
    {
        if(open() && connected())
        {
            RETCODE rc;
            NANODBC_CALL_RC(SQLCancel, rc, stmt_);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

            reset_parameters();

            NANODBC_CALL_RC(SQLFreeHandle, rc, SQL_HANDLE_STMT, stmt_);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        }

        open_ = false;
        stmt_ = 0;
    }

    void cancel()
    {
        RETCODE rc;
        NANODBC_CALL_RC(SQLCancel, rc, stmt_);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

    void prepare(class connection& conn, const string_type& query)
    {
        open(conn);
        prepare(query);
    }

    void prepare(const string_type& query)
    {
        if(!open())
            throw programming_error("statement has no associated open connection");
        RETCODE rc;
        NANODBC_CALL_RC(
            NANODBC_UNICODE(SQLPrepare)
            , rc
            , stmt_
            , (NANODBC_SQLCHAR*)query.c_str()
            , SQL_NTS);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

    result execute_direct(class connection& conn, const string_type& query, long batch_operations, statement& statement)
    {
        open(conn);

        RETCODE rc;
        NANODBC_CALL_RC(
            SQLSetStmtAttr
            , rc
            , stmt_
            , SQL_ATTR_PARAMSET_SIZE
            , (SQLPOINTER)batch_operations
            , 0);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        NANODBC_CALL_RC(
            NANODBC_UNICODE(SQLExecDirect)
            , rc
            , stmt_
            , (NANODBC_SQLCHAR*)query.c_str()
            , SQL_NTS);
        if (!success(rc) && rc != SQL_NO_DATA)
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return result(statement, batch_operations);
    }

    result execute(long batch_operations, statement& statement)
    {
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLSetStmtAttr
            , rc
            , stmt_
            , SQL_ATTR_PARAMSET_SIZE
            , (SQLPOINTER)batch_operations
            , 0);
        if (!success(rc) && rc != SQL_NO_DATA)
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        NANODBC_CALL_RC(SQLExecute, rc, stmt_);
        if (!success(rc) && rc != SQL_NO_DATA)
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return result(statement, batch_operations);
    }

    long affected_rows() const
    {
        SQLLEN rows;
        RETCODE rc;
        NANODBC_CALL_RC(SQLRowCount, rc, stmt_, &rows);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return rows;
    }

    short columns() const
    {
        SQLSMALLINT cols;
        RETCODE rc;
        NANODBC_CALL_RC(SQLNumResultCols, rc, stmt_, &cols);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return cols;
    }

    void reset_parameters() throw()
    {
        NANODBC_CALL(SQLFreeStmt, stmt_, SQL_RESET_PARAMS);
    }

    unsigned long parameter_size(long param) const
    {
        RETCODE rc;
        SQLSMALLINT data_type;
        SQLULEN parameter_size;
        NANODBC_CALL_RC(
            SQLDescribeParam
            , rc
            , stmt_
            , param + 1
            , &data_type
            , &parameter_size
            , 0
            , 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
        return parameter_size;
    }

    template<class T>
    void bind_parameter(long param, const T* value, null_type* nulls, param_direction direction)
    {
        RETCODE rc;
        SQLSMALLINT data_type;
        SQLULEN parameter_size;
        NANODBC_CALL_RC(
            SQLDescribeParam
            , rc
            , stmt_
            , param + 1
            , &data_type
            , &parameter_size
            , 0
            , 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

        SQLSMALLINT param_type;
        switch(direction)
        {
            default:
                assert(false);
                // fallthrough
            case PARAM_IN:
                param_type = SQL_PARAM_INPUT;
                break;
            case PARAM_OUT:
                param_type = SQL_PARAM_OUTPUT;
                break;
            case PARAM_INOUT:
                param_type = SQL_PARAM_INPUT_OUTPUT;
                break;
            case PARAM_RETURN:
                param_type = SQL_PARAM_OUTPUT;
                break;
        }

        NANODBC_CALL_RC(
            SQLBindParameter
            , rc
            , stmt_
            , param + 1
            , param_type
            , sql_type_info<T>::ctype
            , data_type
            , parameter_size // column size ignored for many types, but needed for strings
            , 0
            , (SQLPOINTER)value
            , parameter_size
            , nulls);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
    }

private:
    statement_impl(const statement_impl&); // not defined
    statement_impl& operator=(const statement_impl&); // not defined

private:
    HSTMT stmt_;
    bool open_;
    class connection conn_;
};

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Private Implementation: result
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

class result::result_impl
{
public:
    result_impl(statement stmt, long rowset_size)
    : stmt_(stmt)
    , rowset_size_(rowset_size)
    , row_count_(0)
    , bound_columns_(0)
    , bound_columns_size_(0)
    , rowset_position_(0)
    {
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLSetStmtAttr
            , rc
            , stmt_.native_statement_handle()
            , SQL_ATTR_ROW_ARRAY_SIZE
            , (SQLPOINTER)rowset_size_
            , 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);

        NANODBC_CALL_RC(SQLSetStmtAttr
            , rc
            , stmt_.native_statement_handle()
            , SQL_ATTR_ROWS_FETCHED_PTR
            , &row_count_
            , 0);
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);

        auto_bind();
    }

    ~result_impl() throw()
    {
        before_move();
        delete[] bound_columns_;
    }

    void* native_statement_handle() const
    {
        return stmt_.native_statement_handle();
    }

    long rowset_size() const
    {
        return rowset_size_;
    }

    long affected_rows() const
    {
        return stmt_.affected_rows();
    }

    long rows() const throw()
    {
        return row_count_;
    }

    short columns() const
    {
        return stmt_.columns();
    }

    bool first()
    {
        rowset_position_ = 0;
        return fetch(0, SQL_FETCH_FIRST);
    }

    bool last()
    {
        rowset_position_ = 0;
        return fetch(0, SQL_FETCH_LAST);
    }

    bool next()
    {
        if(rows() && ++rowset_position_ < rowset_size_)
            return rowset_position_ < rows();
        rowset_position_ = 0;
        return fetch(0, SQL_FETCH_NEXT);
    }

    bool prior()
    {
        if(rows() && --rowset_position_ >= 0)
            return true;
        rowset_position_ = 0;
        return fetch(0, SQL_FETCH_PRIOR);
    }

    bool move(long row)
    {
        rowset_position_ = 0;
        return fetch(row, SQL_FETCH_ABSOLUTE);
    }

    bool skip(long rows)
    {
        rowset_position_ += rows;
        if(this->rows() && rowset_position_ < rowset_size_)
            return rowset_position_ < this->rows();
        rowset_position_ = 0;
        return fetch(rows, SQL_FETCH_RELATIVE);
    }

    unsigned long position() const
    {
        SQLULEN pos = 0; // necessary to initialize to 0
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLGetStmtAttr
            , rc
            , stmt_.native_statement_handle()
            , SQL_ATTR_ROW_NUMBER
            , &pos
            , SQL_IS_UINTEGER
            , 0);
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);
        return pos - 1 + rowset_position_;
    }

    bool end() const throw()
    {
        SQLULEN pos = 0; // necessary to initialize to 0
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLGetStmtAttr
            , rc
            , stmt_.native_statement_handle()
            , SQL_ATTR_ROW_NUMBER
            , &pos
            , SQL_IS_UINTEGER
            , 0);
        return (!success(rc) || rows() < 0 || pos - 1 > static_cast<unsigned long>(rows()));
    }

    bool is_null(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        bound_column& col = bound_columns_[column];
        if(rowset_position_ >= rows())
            throw index_range_error();
        return col.cbdata_[rowset_position_] == SQL_NULL_DATA;
    }

    string_type column_name(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        return bound_columns_[column].name_;
    }

    int column_datatype(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        bound_column& col = bound_columns_[column];
        return col.sqltype_;
    }

    bool next_result() const
    {
        RETCODE rc;
        NANODBC_CALL_RC(
            SQLMoreResults
            , rc
            , stmt_.native_statement_handle());
        if(rc == SQL_NO_DATA)
            return false;
        if(!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);
        return true;
    }

    template<class T>
    T get(short column) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        if(is_null(column))
            throw null_access_error();
        return get_impl<T>(column);
    }

    template<class T>
    T get(short column, const T& fallback) const
    {
        if(column >= bound_columns_size_)
            throw index_range_error();
        if(is_null(column))
            return fallback;
        return get_impl<T>(column);
    }

private:
    result_impl(const result_impl&); // not defined
    result_impl& operator=(const result_impl&); // not defined

    template<class T>
    T get_impl(short column) const;

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
        NANODBC_CALL_RC(
            SQLFetchScroll
            , rc
            , stmt_.native_statement_handle()
            , orientation
            , rows);
        if (rc == SQL_NO_DATA)
            return false;
        if (!success(rc))
            NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);
        return true;
    }

    void auto_bind()
    {
        const short n_columns = columns();
        if(n_columns < 1)
            return;

        assert(!bound_columns_);
        assert(!bound_columns_size_);
        bound_columns_ = new bound_column[n_columns];
        bound_columns_size_ = n_columns;

        RETCODE rc;
        NANODBC_SQLCHAR column_name[1024];
        SQLSMALLINT sqltype, scale, nullable, len;
        SQLULEN sqlsize;

        for(SQLSMALLINT i = 0; i < n_columns; ++i)
        {
            NANODBC_CALL_RC(
                NANODBC_UNICODE(SQLDescribeCol)
                , rc
                , stmt_.native_statement_handle()
                , i + 1
                , (NANODBC_SQLCHAR*)column_name
                , sizeof(column_name)
                , &len
                , &sqltype
                , &sqlsize
                , &scale
                , &nullable);
            if(!success(rc))
                NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);

            bound_column& col = bound_columns_[i];
            col.name_ = reinterpret_cast<string_type::value_type*>(column_name);
            col.sqltype_ = sqltype;
            col.sqlsize_ = sqlsize;
            col.scale_ = scale;

            using namespace std; // if int64_t is in std namespace (in c++11)
            switch(col.sqltype_)
            {
                case SQL_BIT:
                case SQL_TINYINT:
                case SQL_SMALLINT:
                case SQL_INTEGER:
                    col.ctype_ = SQL_C_LONG;
                    col.clen_ = sizeof(int32_t);
                    break;
                case SQL_BIGINT:
                    col.ctype_ = SQL_C_SBIGINT;
                    col.clen_ = sizeof(int64_t);
                    break;
                case SQL_DOUBLE:
                case SQL_FLOAT:
                case SQL_DECIMAL:
                case SQL_REAL:
                case SQL_NUMERIC:
                    col.ctype_ = SQL_C_DOUBLE;
                    col.clen_ = sizeof(double);
                    break;
                case SQL_DATE:
                case SQL_TYPE_DATE:
                    col.ctype_ = SQL_C_DATE;
                    col.clen_ = sizeof(date);
                    break;
                case SQL_TIMESTAMP:
                case SQL_TYPE_TIMESTAMP:
                    col.ctype_ = SQL_C_TIMESTAMP;
                    col.clen_ = sizeof(timestamp);
                    break;
                case SQL_CHAR:
                case SQL_VARCHAR:
                    col.ctype_ = SQL_C_CHAR;
                    col.clen_ = col.sqlsize_ + 1;
                    break;
                case SQL_WCHAR:
                case SQL_WVARCHAR:
                    col.ctype_ = SQL_C_WCHAR;
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
                    col.ctype_ = sql_type_info<string_type>::ctype;
                    col.clen_ = 128;
                    break;
            }
        }

        for(SQLSMALLINT i = 0; i < n_columns; ++i)
        {
            bound_column& col = bound_columns_[i];
            col.cbdata_ = new null_type[rowset_size_];
            if(col.blob_)
            {
                NANODBC_CALL_RC(
                    SQLBindCol
                    , rc
                    , stmt_.native_statement_handle()
                    , i + 1
                    , col.ctype_
                    , 0
                    , 0
                    , col.cbdata_);
                if(!success(rc))
                    NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);
            }
            else
            {
                col.rowset_size_ = rowset_size_;
                col.pdata_ = new char[rowset_size_ * col.clen_];
                NANODBC_CALL_RC(
                    SQLBindCol
                    , rc
                    , stmt_.native_statement_handle()
                    , i + 1
                    , col.ctype_
                    , col.pdata_
                    , col.clen_
                    , col.cbdata_);
                if(!success(rc))
                    NANODBC_THROW_DATABASE_ERROR(stmt_.native_statement_handle(), SQL_HANDLE_STMT);
            }
        }
    }

private:
    statement stmt_;
    const long rowset_size_;
    long row_count_;
    bound_column* bound_columns_;
    short bound_columns_size_;
    long rowset_position_;
};

template<>
inline date result::result_impl::get_impl<date>(short column) const
{
    bound_column& col = bound_columns_[column];
    switch(col.ctype_)
    {
        case SQL_C_DATE:
            return *((date*)(col.pdata_ + rowset_position_ * col.clen_));
        case SQL_C_TIMESTAMP:
        {
            timestamp stamp = *((timestamp*)(col.pdata_ + rowset_position_ * col.clen_));
            date d = { stamp.year, stamp.month, stamp.day };
            return d;
        }
    }
    throw type_incompatible_error();
}

template<>
inline timestamp result::result_impl::get_impl<timestamp>(short column) const
{
    bound_column& col = bound_columns_[column];
    switch(col.ctype_)
    {
        case SQL_C_DATE:
        {
            date d = *((date*)(col.pdata_ + rowset_position_ * col.clen_));
            timestamp stamp = { d.year, d.month, d.day, 0, 0 , 0, 0 };
            return stamp;
        }
        case SQL_C_TIMESTAMP:
            return *((timestamp*)(col.pdata_ + rowset_position_ * col.clen_));
    }
    throw type_incompatible_error();
}

template<>
inline string_type result::result_impl::get_impl<string_type>(short column) const
{
    const bound_column& col = bound_columns_[column];
    const SQLULEN column_size = col.sqlsize_;
    
    switch(col.ctype_)
    {
        case SQL_C_CHAR:
        {
            if(col.blob_)
                throw std::runtime_error("blob not implemented yet");
            const char* s = col.pdata_ + rowset_position_ * col.clen_;
            const std::string::size_type str_size = std::strlen(s);
            string_type rvalue(s, s + str_size);
            return rvalue;
        }

        case SQL_C_WCHAR:
        {
            if(col.blob_)
                throw std::runtime_error("blob not implemented yet");
            const wchar_t* s = reinterpret_cast<wchar_t*>(col.pdata_ + rowset_position_ * col.clen_);
            const std::wstring::size_type str_size = std::wcslen(s);
            return string_type(s, s + str_size);
        }

        case SQL_C_GUID:
        case SQL_C_BINARY:
        {
            if(col.blob_)
                throw std::runtime_error("blob not implemented yet");
            const char* s = col.pdata_ + rowset_position_ * col.clen_;
            return string_type(s, s + column_size);
        }

        case SQL_C_LONG:
        case SQL_C_SBIGINT:
        {
            string_type buffer(column_size, 0);
            if(NANODBC_SNPRINTF(
                    const_cast<string_type::value_type*>(buffer.data())
                    , column_size
                    , NANODBC_TEXT("%ld")
                    , *(long*)(col.pdata_ + rowset_position_ * col.clen_)) == -1)
                throw type_incompatible_error();
            buffer.resize(strlen(buffer.c_str()));
            return buffer;
        }

        case SQL_C_FLOAT:
        {
            string_type buffer(column_size, 0);
            if(NANODBC_SNPRINTF(
                    const_cast<string_type::value_type*>(buffer.data())
                    , column_size
                    , NANODBC_TEXT("%f")
                    , *(float*)(col.pdata_ + rowset_position_ * col.clen_)) == -1)
                throw type_incompatible_error();
            buffer.resize(strlen(buffer.c_str()));
            return buffer;
        }

        case SQL_C_DOUBLE:
        {
            string_type buffer(column_size, 0);
            if(NANODBC_SNPRINTF(
                    const_cast<string_type::value_type*>(buffer.data())
                    , column_size
                    , NANODBC_TEXT("%lf")
                    , *(double*)(col.pdata_ + rowset_position_ * col.clen_)) == -1)
                throw type_incompatible_error();
            buffer.resize(strlen(buffer.c_str()));
            return buffer;
        }

        case SQL_C_DATE:
        {
            date d = *((date*)(col.pdata_ + rowset_position_ * col.clen_));
            std::tm st = { 0 };
            st.tm_year = d.year - 1900;
            st.tm_mon = d.month - 1;
            st.tm_mday = d.day;
            char* old_lc_time = std::setlocale(LC_TIME, NULL);
            std::setlocale(LC_TIME, "");
            string_type::value_type date_str[512];
            NANODBC_STRFTIME(date_str, sizeof(date_str) / sizeof(string_type::value_type), NANODBC_TEXT("%F"), &st);
            std::setlocale(LC_TIME, old_lc_time);
            return string_type(date_str);
        }

        case SQL_C_TIMESTAMP:
        {
            timestamp stamp = *((timestamp*)(col.pdata_ + rowset_position_ * col.clen_));
            std::tm st = { 0 };
            st.tm_year = stamp.year - 1900;
            st.tm_mon = stamp.month - 1;
            st.tm_mday = stamp.day;
            st.tm_hour = stamp.hour;
            st.tm_min = stamp.min;
            st.tm_sec = stamp.sec;
            char* old_lc_time = std::setlocale(LC_TIME, NULL);
            std::setlocale(LC_TIME, "");
            string_type::value_type date_str[512];
            NANODBC_STRFTIME(date_str, sizeof(date_str) / sizeof(string_type::value_type), NANODBC_TEXT("%FT%H:%M:%S%z"), &st);
            std::setlocale(LC_TIME, old_lc_time);
            return string_type(date_str);
        }
    }
    throw type_incompatible_error();
}

template<class T>
T result::result_impl::get_impl(short column) const
{
    bound_column& col = bound_columns_[column];
    using namespace std; // if int64_t is in std namespace (in c++11)
    const char* s = col.pdata_ + rowset_position_ * col.clen_;
    switch(col.ctype_)
    {
        case SQL_C_CHAR: return (T)*(char*)(s);
        case SQL_C_SSHORT: return (T)*(short*)(s);
        case SQL_C_USHORT: return (T)*(unsigned short*)(s);
        case SQL_C_LONG: return (T)*(long*)(s);
        case SQL_C_SLONG: return (T)*(long*)(s);
        case SQL_C_ULONG: return (T)*(unsigned long*)(s);
        case SQL_C_FLOAT: return (T)*(float*)(s);
        case SQL_C_DOUBLE: return (T)*(double*)(s);
        case SQL_C_SBIGINT: return (T)*(int64_t*)(s);
        case SQL_C_UBIGINT: return (T)*(uint64_t*)(s);
    }
    throw type_incompatible_error();
}

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Free Functions
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

result execute(connection& conn, const string_type& query, long batch_operations)
{
    class statement statement;
    return statement.execute_direct(conn, query, batch_operations);
}

result execute(statement& stmt, long batch_operations)
{
    return stmt.execute(batch_operations);
}

result transact(statement& stmt, long batch_operations)
{
    class transaction transaction(stmt.connection());
    result rvalue = stmt.execute(batch_operations);
    transaction.commit();
    return rvalue;
}

void prepare(statement& stmt, const string_type& query)
{
    stmt.prepare(query);
}

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Pimpl Forwards: connection
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

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

connection::connection(const string_type& dsn, const string_type& user, const string_type& pass, long timeout)
: impl_(new connection_impl(dsn, user, pass, timeout))
{

}

connection::connection(const string_type& connection_string, long timeout)
: impl_(new connection_impl(connection_string, timeout))
{

}

connection::~connection() throw()
{

}

void connection::connect(const string_type& dsn, const string_type& user, const string_type& pass, long timeout)
{
    impl_->connect(dsn, user, pass, timeout);
}

void connection::connect(const string_type& connection_string, long timeout)
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

void* connection::native_dbc_handle() const
{
    return impl_->native_dbc_handle();
}

void* connection::native_env_handle() const
{
    return impl_->native_env_handle();
}

string_type connection::driver_name() const
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

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Pimpl Forwards: transaction
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

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

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Pimpl Forwards: statement
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

statement::statement()
: impl_(new statement_impl())
{

}

statement::statement(class connection& conn)
: impl_(new statement_impl(conn))
{

}

statement::statement(class connection& conn, const string_type& query)
: impl_(new statement_impl(conn, query))
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

void statement::open(class connection& conn)
{
    impl_->open(conn);
}

bool statement::open() const
{
    return impl_->open();
}

bool statement::connected() const
{
    return impl_->connected();
}

const class connection& statement::connection() const
{
    return impl_->connection();
}

class connection& statement::connection()
{
    return impl_->connection();
}

void* statement::native_statement_handle() const
{
    return impl_->native_statement_handle();
}

void statement::close()
{
    impl_->close();
}

void statement::cancel()
{
    impl_->cancel();
}

void statement::prepare(class connection& conn, const string_type& query)
{
    impl_->prepare(conn, query);
}

void statement::prepare(const string_type& query)
{
    impl_->prepare(query);
}

result statement::execute_direct(class connection& conn, const string_type& query, long batch_operations)
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

short statement::columns() const
{
    return impl_->columns();
}

void statement::reset_parameters() throw()
{
    impl_->reset_parameters();
}

unsigned long statement::parameter_size(long param) const
{
    return impl_->parameter_size(param);
}

template<class T>
void statement::bind_parameter(long param, const T* value, null_type* nulls, param_direction direction)
{
    impl_->bind_parameter(param, reinterpret_cast<const T*>(value), nulls, direction);
}

// The following are the only supported instantiations of statement::bind_parameter().
template void statement::bind_parameter(long, const char*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const short*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const unsigned short*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const int32_t*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const uint32_t*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const int64_t*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const uint64_t*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const float*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const double*, nanodbc::null_type*, param_direction);
template void statement::bind_parameter(long, const date*, nanodbc::null_type*, param_direction);

} // namespace nanodbc

///////////////////////////////////////////////////////////////////////////////
// Pimpl Forwards: result
///////////////////////////////////////////////////////////////////////////////

namespace nanodbc
{

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

void* result::native_statement_handle() const
{
    return impl_->native_statement_handle();
}

long result::rowset_size() const throw()
{
    return impl_->rowset_size();
}

long result::affected_rows() const
{
    return impl_->affected_rows();
}

long result::rows() const throw()
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

unsigned long result::position() const
{
    return impl_->position();
}

bool result::end() const throw()
{
    return impl_->end();
}

bool result::is_null(short column) const
{
    return impl_->is_null(column);
}

string_type result::column_name(short column) const
{
    return impl_->column_name(column);
}

int result::column_datatype(short column) const
{
    return impl_->column_datatype(column);
}

bool result::next_result() const
{
    return impl_->next_result();
}

template<class T>
T result::get(short column) const
{
    return impl_->get<T>(column);
}

template<class T>
T result::get(short column, const T& fallback) const
{
    return impl_->get<T>(column, fallback);
}

// The following are the only supported instantiations of result::get().
template string_type::value_type result::get(short) const;
template short result::get(short) const;
template unsigned short result::get(short) const;
template long result::get(short) const;
template unsigned long result::get(short) const;
template long long result::get(short) const;
template unsigned long long result::get(short) const;
template int result::get(short) const;
template unsigned int result::get(short) const;
template float result::get(short) const;
template double result::get(short) const;
template string_type result::get(short) const;
template date result::get(short) const;
template timestamp result::get(short) const;

// The following are the only supported instantiations of result::get() with fallback.
template string_type::value_type result::get(short, const string_type::value_type&) const;
template short result::get(short, const short&) const;
template unsigned short result::get(short, const unsigned short&) const;
template long result::get(short, const long&) const;
template unsigned long result::get(short, const unsigned long&) const;
template long long result::get(short, const long long&) const;
template unsigned long long result::get(short, const unsigned long long&) const;
template int result::get(short, const int&) const;
template unsigned int result::get(short, const unsigned int&) const;
template float result::get(short, const float&) const;
template double result::get(short, const double&) const;
template string_type result::get(short, const string_type&) const;
template date result::get(short, const date&) const;
template timestamp result::get(short, const timestamp&) const;

} // namespace nanodbc

#undef NANODBC_THROW_DATABASE_ERROR
#undef NANODBC_STRINGIZE
#undef NANODBC_STRINGIZE_I
#undef NANODBC_CALL_RC
#undef NANODBC_CALL
