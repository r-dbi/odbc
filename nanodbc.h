//! \file nanodbc.h The entirety of nanodbc can be found within this file and nanodbc.cpp.

//! \mainpage
//! 
//! \section toc Table of Contents
//! \li \ref license "License"
//! \li \ref credits "Credits"
//! \li \ref examples "Example Usage"
//! \li \ref nanodbc "Namespace Reference"
//! \li <a href="https://nanodbc.googlecode.com">Project Homepage</a>
//! 
//! \section license License
//! Copyright (C) 2012 Amy Troschinetz amy@lexicalunit.com
//! 
//! The MIT License
//! 
//! Permission is hereby granted, free of charge, to any person obtaining a copy
//! of this software and associated documentation files (the "Software"), to deal
//! in the Software without restriction, including without limitation the rights
//! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//! copies of the Software, and to permit persons to whom the Software is
//! furnished to do so, subject to the following conditions:
//! 
//! The above copyright notice and this permission notice shall be included in
//! all copies or substantial portions of the Software.
//! 
//! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//! THE SOFTWARE.
//! 
//! \section credits Credits
//! Much of the code in this file was originally derived from TinyODBC.<br />
//! TinyODBC is hosted at http://code.google.com/p/tiodbc/<br />
//! Copyright (C) 2008 SqUe squarious@gmail.com<br />
//! License: The MIT License<br />
//! 
//! Transaction support was based on the implementation in SimpleDB: C++ ODBC database API.<br/>
//! SimpleDB is hosted at http://simpledb.sourceforge.net<br/>
//! Copyright (C) 2006 Eminence Technology Pty Ltd<br/>
//! Copyright (C) 2008-2010,2012 Russell Kliese russell@kliese.id.au<br/>
//! License: GNU Lesser General Public version 2.1<br/>
//! 
//! Some improvements and features are based on The Python ODBC Library.<br/>
//! The Python ODBC Library is hosted at http://code.google.com/p/pyodbc/<br/>
//! License: The MIT License<br/>
//! 
//! Implementation of column binding inspired by Nick E. Geht's source code posted to on CodeGuru.<br />
//! GSODBC hosted at http://www.codeguru.com/mfc_database/gsodbc.html<br />
//! Copyright (C) 2002 Nick E. Geht<br />
//! License: Perpetual license to reproduce, distribute, adapt, perform, display, and sublicense.<br/>
//! See http://www.codeguru.com/submission-guidelines.php for details.<br />

//! \page examples Example Usage
//! \brief Example library usage.
//! \include example.cpp

#ifndef NANODBC_H
#define NANODBC_H

#include <sql.h>
#include <sqlext.h>

#include <algorithm>
#include <cstring>
#include <stdexcept>
#include <string>

// You must explicitly request C++11 support by defining NANODBC_USE_CPP11 at compile time, otherwise nanodbc will assume it must use tr1 instead.
#ifndef NANODBC_USE_CPP11
    #include <tr1/cstdint>
    #include <tr1/memory>
    #include <tr1/type_traits>
    #define NANODBC_STD std::tr1::
#else
    #include <cstdint>
    #include <memory>
    #include <type_traits>
    #define NANODBC_STD std::
#endif

//! \brief The entirety of nanodbc can be found within this one namespace.
//! \todo Implement retrieval of blob data.
//! \todo Support unicode operation.
//! \todo Implement reflective features for columns, such as type, to enable visitation.
namespace nanodbc
{

class connection;
class result;
struct date;
struct timestamp;

namespace detail
{
    // Simple enable/disable if utility taken from boost.
    template <bool B, class T = void> struct enable_if_c { typedef T type; };
    template <class T> struct enable_if_c<false, T> { };
    template <bool B, class T = void> struct disable_if_c { typedef T type; };
    template <class T> struct disable_if_c<true, T> { };

    // A utility for calculating the ctype, sqltype, and format specifiers for the given type T.
    // I essentially create a lookup table based on the MSDN ODBC documentation.
    // See http://msdn.microsoft.com/en-us/library/windows/desktop/ms714556(v=vs.85).aspx for details.
    template<class T>
    struct sql_type_info { };

    template<>
    struct sql_type_info<short>
    {
        static const SQLSMALLINT ctype = SQL_C_SSHORT;
        static const SQLSMALLINT sqltype = SQL_SMALLINT; 
        static const char* const format;
    };

    template<>
    struct sql_type_info<unsigned short>
    { 
        static const SQLSMALLINT ctype = SQL_C_USHORT; 
        static const SQLSMALLINT sqltype = SQL_SMALLINT;    
        static const char* const format; 
    };

    template<>
    struct sql_type_info<long>
    { 
        static const SQLSMALLINT ctype = SQL_C_SLONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const char* const format; 
    };

    template<>
    struct sql_type_info<unsigned long>
    { 
        static const SQLSMALLINT ctype = SQL_C_ULONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const char* const format; 
    };

    template<>
    struct sql_type_info<int>
    { 
        static const SQLSMALLINT ctype = SQL_C_SLONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const char* const format; 
    };

    template<>
    struct sql_type_info<unsigned int>
    { 
        static const SQLSMALLINT ctype = SQL_C_ULONG; 
        static const SQLSMALLINT sqltype = SQL_INTEGER; 
        static const char* const format; 
    };

    template<>
    struct sql_type_info<float>
    { 
        static const SQLSMALLINT ctype = SQL_C_FLOAT; 
        static const SQLSMALLINT sqltype = SQL_REAL;
        static const char* const format; 
    };

    template<>
    struct sql_type_info<double>
    { 
        static const SQLSMALLINT ctype = SQL_C_DOUBLE; 
        static const SQLSMALLINT sqltype = SQL_DOUBLE;
        static const char* const format; 
    };

    template<>
    struct sql_type_info<std::string>
    { 
        static const SQLSMALLINT ctype = SQL_C_CHAR; 
        static const SQLSMALLINT sqltype = SQL_CHAR;
        static const char* const format; 
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
} // namespace detail

//! \addtogroup exceptions Exception Types
//! \brief Possible error conditions.
//!
//! Specific errors such as type_incompatible_error, null_access_error, and index_range_error can arise
//! from improper use of the nanodbc library. The general database_error is for all other situations
//! in which the ODBC driver or C API reports an error condition. The explanatory string for database_error
//! will, if possible, contain a diagnostic message obtained from SQLGetDiagRec().
//! @{

//! \brief Type incompatible.
//! \see exceptions
class type_incompatible_error : public std::runtime_error
{
public:
    //! \brief Constructor.
    type_incompatible_error();
    
    //! \brief Returns the explanatory string.
    const char* what() const throw();
};

//! \brief Accessed null data.
//! \see exceptions
class null_access_error : public std::runtime_error
{
public:
    //! \brief Constructor.
    null_access_error();
    
    //! \brief Returns the explanatory string.
    const char* what() const throw();
};

//! \brief Index out of range.
//! \see exceptions
class index_range_error : public std::runtime_error
{
public:
    //! \brief Constructor.
    index_range_error();
    
    //! \brief Returns the explanatory string.
    const char* what() const throw();
};

//! \brief General database error.
//! \see exceptions
class database_error : public std::runtime_error
{
public:
    //! \brief Creates a runtime_error with a message describing the last ODBC error generated for the given handle and handle_type.
    //! \param handle The native ODBC statement or connection handle.
    //! \param handle_type The native ODBC handle type code for the given handle.
    //! \param info Additional information that will be appended to the beginning of the error message.
    database_error(SQLHANDLE handle, SQLSMALLINT handle_type, const std::string& info = "");

    //! \brief Returns the explanatory string.
    const char* what() const throw();
};

//! @}

//! \addtogroup utility Utility Classes
//! \brief Additional nanodbc utility classes.
//!
//! \{

//! \brief A type for representing date data.
struct date
{
    NANODBC_STD int16_t year; //!< Year [0-inf).
    NANODBC_STD int16_t month; //!< Month of the year [1-12].
    NANODBC_STD int16_t day; //!< Day of the month [1-31].
};

//! \brief A type for representing timestamp data.
struct timestamp
{
    NANODBC_STD int16_t year; //!< Year [0-inf).
    NANODBC_STD int16_t month; //!< Month of the year [1-12].
    NANODBC_STD int16_t day; //!< Day of the month [1-31].
    NANODBC_STD int16_t hour; //!< Hours since midnight [0-23].
    NANODBC_STD int16_t min; //!< Minutes after the hour [0-59].
    NANODBC_STD int16_t sec; //!< Seconds after the minute.
    NANODBC_STD int32_t fract; //!< Fractional seconds.
};

//! \brief A type for representing the data type of a column.
enum column_datatype
{
    column_short = SQL_C_SSHORT             //!< Signed short type.
    , column_ushort = SQL_C_USHORT          //!< Unsigned short type.
    , column_long = SQL_C_SLONG             //!< Signed long type.
    , column_ulong = SQL_C_ULONG            //!< Unsigned long type.
    , column_float = SQL_C_FLOAT            //!< Float point type.
    , column_double = SQL_C_DOUBLE          //!< Double precision floating point type
    , column_string = SQL_C_CHAR            //!< String type
    , column_date = SQL_C_DATE              //!< Date type.
    , column_timestamp = SQL_C_TIMESTAMP    //!< Timestamp type.
};

//! \}

//! \addtogroup main Main Classes
//! \brief Main nanodbc classes.
//!
//! @{

//! \brief A resource for managing transaction commits and rollbacks.
//!
//! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
class transaction
{
public:
    //! \brief Begin a transaction on the given connection object.
    //! \post Operations that modify the database must now be committed before taking effect.
    //! \throws database_error
    explicit transaction(const class connection& conn);

    //! Copy constructor.
    transaction(const transaction& rhs);

    //! Assignment.
    transaction& operator=(transaction rhs);

    //! Member swap.
    void swap(transaction& rhs) throw();

    //! \brief If this transaction has not been committed, will will rollback any modifying operations.
    ~transaction() throw();

    //! \brief Marks this transaction for commit.
    //! \throws database_error
    void commit();

    //! \brief Marks this transaction for rollback.
    void rollback() throw();

    //! Returns the connection object.
    class connection& connection();

    //! Returns the connection object.
    const class connection& connection() const;

    //! Returns the connection object.
    operator class connection&();

    //! Returns the connection object.
    operator const class connection&() const;

private:
    class transaction_impl;
    friend class nanodbc::connection;

private:
    NANODBC_STD shared_ptr<transaction_impl> impl_;
};

//! \brief Manages and encapsulates ODBC resources such as the connection and environment handles.
class connection
{
public:
    //! \brief Create new connection object, initially not connected.
    connection();

    //! Copy constructor.
    connection(const connection& rhs);

    //! Assignment.
    connection& operator=(connection rhs);

    //! Member swap.
    void swap(connection&) throw();

    //! \brief Create new connection object and immediately connect to the given data source.
    //! \param dsn The name of the data source.
    //! \param user The username for authenticating to the data source.
    //! \param pass The password for authenticating to the data source.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected(), connect()
    connection(const std::string& dsn, const std::string& user, const std::string& pass, long timeout = 5);

    //! \brief Create new connection object and immediately connect using the given connection string.
    //! \param connection_string The connection string for establishing a connection.
    //! \throws database_error
    //! \see connected(), connect()
    connection(const std::string& connection_string, long timeout = 5);

    //! \brief Automatically disconnects from the database and frees all associated resources.
    ~connection() throw();

    //! \brief Create new connection object and immediately connect to the given data source.
    //! \param dsn The name of the data source.
    //! \param user The username for authenticating to the data source.
    //! \param pass The password for authenticating to the data source.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected()
    void connect(const std::string& dsn, const std::string& user, const std::string& pass, long timeout = 5);

    //! \brief Create new connection object and immediately connect using the given connection string.
    //! \param connection_string The connection string for establishing a connection.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected()
    void connect(const std::string& connection_string, long timeout = 5);

    //! \brief Returns true if connected to the database.
    bool connected() const;

    //! \brief Disconnects from the database, but maintains environment and handle resources.
    void disconnect() throw();

    //! \brief Returns the number of transactions currently held for this connection.
    std::size_t transactions() const;

    //! \brief Returns the native ODBC database connection handle.
    HDBC native_dbc_handle() const;

    //! \brief Returns the native ODBC environment handle.
    HDBC native_env_handle() const;

    //! \brief Returns the name of the ODBC driver.
    //! \throws database_error
    std::string driver_name() const;

private:
    std::size_t ref_transaction();
    std::size_t unref_transaction();
    bool rollback() const;
    void rollback(bool onoff);

private:
    class connection_impl;
    friend class nanodbc::transaction::transaction_impl;

private:
    NANODBC_STD shared_ptr<connection_impl> impl_;
};

//! \brief Represents a statement on the database.
class statement
{
public:
    //! \brief Creates a new un-prepared statement.
    //! \see execute(), execute_direct(), open(), prepare()
    statement();

    //! \brief Constructs and prepares a statement using the given connection and query.
    //! \param conn The connection to use.
    //! \param stmt The SQL query statement.
    //! \see execute(), execute_direct(), open(), prepare()
    statement(connection& conn, const std::string& stmt);

    //! Copy constructor.
    statement(const statement& rhs);

    //! Assignment.
    statement& operator=(statement rhs);

    //! Member swap.
    void swap(statement& rhs) throw();

    //! \brief Closes the statement.
    //! \see close()
    ~statement() throw();

    //! \brief Creates a statement for the given connection.
    //! \param conn The connection where the statement will be executed.
    //! \throws database_error
    void open(connection& conn);

    //! \brief Returns true if connection is open.
    bool open() const;

    //! \brief Returns the native ODBC statement handle.
    HDBC native_stmt_handle() const;

    //! \brief Closes the statement and frees all associated resources.
    void close();

    //! \brief Cancels execution of the statement.
    //! \throws database_error
    void cancel();

    //! \brief Opens and prepares the given statement to execute on the given connection.
    //! \param conn The connection where the statement will be executed.
    //! \param stmt The SQL query that will be executed.
    //! \see open()
    //! \throws database_error
    void prepare(connection& conn, const std::string& stmt);

    //! \brief Immediately opens, prepares, and executes the given query directly on the given connection.
    //! \param conn The connection where the statement will be executed.
    //! \param stmt The SQL query that will be executed.
    //! \param batch_operations Numbers of rows to fetch per rowset, or the number of batch parameters to process.
    //! \return A result set object.
    //! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
    //! \see open(), prepare(), execute(), result, transaction
    result execute_direct(connection& conn, const std::string& query, long batch_operations = 1);

    //! \brief Execute the previously prepared query now.
    //! \param batch_operations Numbers of rows to fetch per rowset, or the number of batch parameters to process.
    //! \throws database_error
    //! \return A result set object.
    //! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
    //! \see open(), prepare(), execute(), result, transaction
    result execute(long batch_operations = 1);

    //! \brief Returns the number of rows affected by the request or –1 if the number of affected rows is not available.
    //! \throws database_error
    long affected_rows() const;

    //! \brief Resets all currently bound parameters.
    void reset_parameters() throw();

    //! \brief Binds the given value to the given parameter placeholder number in the prepared statement.
    //!
    //! If your prepared SQL query has any ? placeholders, this is how you bind values to them.
    //! Placeholder numbers count from left to right and are 0-indexed.
    //! \param param Placeholder position.
    //! \param value Value to substitute into placeholder.
    //! \throws database_error
    template<class T>
    void bind_parameter(long param, const T& value);

    //! \brief Binds a number of values to the given parameter placeholder number in the prepared statement for batch operation.
    //! 
    //! \param param Placeholder position.
    //! \param first Iterator to first value to bind.
    //! \param first Iterator to one past the last value to bind.
    //! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
    //! \throws database_error
    //! \see transaction
    template<class InputIterator>
    #ifndef DOXYGEN
        typename detail::disable_if_c<
            NANODBC_STD is_convertible<
                typename std::iterator_traits<InputIterator>::value_type
                , std::string
            >::value
        >::type
    #else
        void
    #endif
    bind_parameter(long param, InputIterator first, InputIterator last)
    {
        using std::distance;
        using std::copy;
        typedef typename std::iterator_traits<InputIterator>::value_type element_type;
        typedef typename std::iterator_traits<InputIterator>::difference_type size_type;
        const size_type elements = distance(first, last);

        element_type* data = new element_type[elements];
        copy(first, last, data);

        bind_parameter(
            param
            , detail::sql_type_info<element_type>::ctype
            , detail::sql_type_info<element_type>::sqltype
            , (char*)data
            , sizeof(element_type)
            , elements
            , true);
    }

    #ifndef DOXYGEN
    template<class InputIterator>
    typename detail::enable_if_c<
        NANODBC_STD is_convertible<
            typename std::iterator_traits<InputIterator>::value_type
            , std::string
        >::value
    >::type
    bind_parameter(long param, InputIterator first, InputIterator last)
    {
        using std::distance;
        using std::copy;
        typedef typename std::iterator_traits<InputIterator>::value_type element_type;
        typedef typename std::iterator_traits<InputIterator>::difference_type size_type;
        const size_type elements = distance(first, last);
        const unsigned long column_size = parameter_column_size(param);

        char* cdata = new char[elements * column_size];
        size_type row = 0;
        for(InputIterator i = first; i != last; ++i)
            std::strncpy(&cdata[row++ * column_size], std::string(*i).c_str(), column_size);

        bind_parameter(
            param
            , detail::sql_type_info<element_type>::ctype
            , detail::sql_type_info<element_type>::sqltype
            , cdata
            , column_size
            , elements
            , true);
    }
    #endif // DOXYGEN

private:
    void bind_parameter(
        long param
        , SQLSMALLINT ctype
        , SQLSMALLINT sqltype
        , char* data
        , std::size_t element_size
        , std::size_t elemnts
        , bool take_ownership);

    unsigned long parameter_column_size(long param) const;

private:
    class statement_impl;
    friend class nanodbc::result;

private:
    NANODBC_STD shared_ptr<statement_impl> impl_;
};

//! \brief A resource for managing result sets from statement execution.
//!
//! \see statement::execute(), statement::execute_direct()
//! \note result objects may be copied, however all copies will refer to the same underlying ODBC result set.
class result
{
public:
    //! Empty result set.
    result();

    //! Free result set.
    ~result() throw();

    //! Copy constructor.
    result(const result& rhs);

    //! Assignment.
    result& operator=(result rhs);

    //! Member swap.
    void swap(result& rhs) throw();

    //! \brief Returns the native ODBC statement handle.
    HDBC native_stmt_handle() const;

    //! \brief The rowset size for this result set.
    long rowset_size() const throw();

    //! \brief Returns the number of rows affected by the request or –1 if the number of affected rows is not available.
    //! \throws database_error
    long affected_rows() const;

    //! \brief Returns the number of rows in the current rowset or 0 if the number of rows is not available.
    long rows() const throw();

    //! \brief Returns the number of columns in the current result set.
    //! \throws database_error
    short columns() const;

    //! \brief Fetches the first row in the current result set.
    //! \return true if there are more results or false otherwise.
    //! \throws database_error
    bool first();

    //! \brief Fetches the last row in the current result set.
    //! \return true if there are more results or false otherwise.
    //! \throws database_error
    bool last();

    //! \brief Fetches the next row in the current result set.
    //! \return true if there are more results or false otherwise.
    //! \throws database_error
    bool next();

    //! \brief Fetches the prior row in the current result set.
    //! \return true if there are more results or false otherwise.
    //! \throws database_error
    bool prior();

    //! \brief Moves to and fetches the specified row in the current result set.
    //! \return true if there are results or false otherwise.
    //! \throws database_error
    bool move(long row);

    //! \brief Skips a number of rows and then fetches the resulting row in the current result set.
    //! \return true if there are results or false otherwise.
    //! \throws database_error
    bool skip(long rows);

    //! \brief Returns the row position in the current result set.
    unsigned long position() const;

    //! \brief Returns true if there are no more results in the current result set.
    bool end() const throw();

    //! \brief Gets data from the given column in the selected row of the current rowset.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \param row If there are multiple rows in this rowset, get from the specified row.
    //! \throws database_error, index_range_error, type_incompatible_error
    template<class T>
    T get(short column, long row = 0) const;

    //! \brief Returns true if and only if the given column in the selected row of the current rowset is null.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \param row If there are multiple rows in this rowset, get from the specified row.
    //! \throws database_error, index_range_error
    bool is_null(short column, long row = 0) const;

    //! \brief Returns the name of the specified column.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \throws index_range_error
    std::string column_name(short column) const;

    //! Returns a column_datatype representing the C type of this column.
    enum column_datatype column_datatype(short column) const;

private:
    result(statement stmt, long rowset_size);

private:
    class result_impl;
    friend class nanodbc::statement::statement_impl;

private:
    NANODBC_STD shared_ptr<result_impl> impl_;
};

//! @}

} // namespace nanodbc

#endif // NANODBC_H
