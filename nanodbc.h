//! \file nanodbc.h The entirety of nanodbc can be found within this file and nanodbc.cpp.

/*! \mainpage

\section toc Table of Contents
\li \ref license "License"
\li \ref credits "Credits"
\li \ref examples "Example Usage"
\li \ref nanodbc "Namespace Reference"
\li <a href="https://nanodbc.googlecode.com">Project Homepage</a>

\section license License
Copyright (C) 2012 Amy Troschinetz amy@lexicalunit.com

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

\section credits Credits
Much of the code in this file was originally derived from TinyODBC.<br />
TinyODBC is hosted at http://code.google.com/p/tiodbc/<br />
Copyright (C) 2008 SqUe squarious@gmail.com<br />
License: The MIT License<br />

Transaction support was based on the implementation in SimpleDB: C++ ODBC database API.<br/>
SimpleDB is hosted at http://simpledb.sourceforge.net<br/>
Copyright (C) 2006 Eminence Technology Pty Ltd<br/>
Copyright (C) 2008-2010,2012 Russell Kliese russell@kliese.id.au<br/>
License: GNU Lesser General Public version 2.1<br/>

Some improvements and features are based on The Python ODBC Library.<br/>
The Python ODBC Library is hosted at http://code.google.com/p/pyodbc/<br/>
License: The MIT License<br/>

Implementation of column binding inspired by Nick E. Geht's source code posted to on CodeGuru.<br />
GSODBC hosted at http://www.codeguru.com/mfc_database/gsodbc.html<br />
Copyright (C) 2002 Nick E. Geht<br />
License: Perpetual license to reproduce, distribute, adapt, perform, display, and sublicense.<br/>
See http://www.codeguru.com/submission-guidelines.php for details.<br />
*/

/*! \page examples Example Usage
\brief Example library usage.
\include example.cpp
*/

#ifndef NANODBC_H
#define NANODBC_H

#include <sql.h>
#include <sqlext.h>

#include <algorithm>
#include <cstdio>
#include <map>
#include <stdexcept>
#include <string>
#include <tr1/cstdint>
#include <tr1/memory>
#include <tr1/type_traits>

//! \brief The entirety of nanodbc can be found within this one namespace.
namespace nanodbc
{

class result;
class statement;
class transaction;

namespace detail
{
    class result_impl;
    class statement_impl;
    class bound_parameter;
    typedef std::tr1::shared_ptr<result_impl> result_impl_ptr;
    typedef std::tr1::shared_ptr<statement_impl> statement_impl_ptr;

    class bound_column
    {
    public:
        ~bound_column()
        {
            delete[] cbdata_;
            delete[] pdata_;
        }

    private:
        bound_column(const bound_column& rhs); // not defined
        bound_column& operator=(bound_column rhs); // not defined

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

    private:
        friend class nanodbc::result;
        friend class nanodbc::detail::result_impl;

    private:
        std::string name_;
        SQLSMALLINT sqltype_;
        SQLULEN sqlsize_;
        SQLSMALLINT scale_;
        SQLSMALLINT ctype_;
        SQLSMALLINT clen_;
        bool blob_;
        unsigned long rowset_size_;
        long* cbdata_;
        char* pdata_;
    };

    void statement_bind_parameter_value(
        statement* me
        , long param
        , SQLSMALLINT ctype
        , SQLSMALLINT sqltype
        , char* data
        , std::size_t element_size
        , std::size_t elemnts
        , bool take_ownership);
    void statement_bind_parameter_string(statement* me, long param, const std::string& string);
    bound_column& result_impl_get_bound_column(result_impl_ptr me, short column, unsigned long row);
    void describe_parameter_column_size(HSTMT stmt, long param, SQLULEN& column_size);

    // simple enable/disable if utility taken from boost
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

    // Converts the given string to the given type T.
    template<class T>
    inline T convert(const std::string& s)
    {
        T value;
        std::sscanf(s.c_str(), detail::sql_type_info<T>::format, &value);
        return value;
    }

    template<>
    inline std::string convert<std::string>(const std::string& s)
    {
        return s;
    }
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
struct date_type
{
    std::tr1::int16_t year; //!< Year.
    std::tr1::int16_t month; //!< Month.
    std::tr1::int16_t day; //!< Day.
};

//! \brief A type for representing timestamp data.
struct timestamp_type
{
    std::tr1::int16_t year; //!< Year.
    std::tr1::int16_t month; //!< Month.
    std::tr1::int16_t day; //!< Day.
    std::tr1::int16_t hour; //!< 24 Hour.
    std::tr1::int16_t min; //!< Min.
    std::tr1::int16_t sec; //!< Seconds.
    std::tr1::int32_t fract; //!< Fractional seconds.
};

//! \}

//! \addtogroup main Main Classes
//! \brief Main nanodbc classes.
//!
//! @{

//! \brief Manages and encapsulates ODBC resources such as the connection and environment handles.
//!
//! \note connections are non-copyable.
class connection
{
public:
    //! \brief Create new connection object, initially not connected.
    connection();

    //! \brief Create new connection object and immediately connect to the given data source.
    //! \param dsn The name of the data source.
    //! \param user The username for authenticating to the data source.
    //! \param pass The password for authenticating to the data source.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected(), connect()
    connection(const std::string& dsn, const std::string& user, const std::string& pass, int timeout = 5);

    //! \brief Create new connection object and immediately connect using the given connection string.
    //! \param connection_string The connection string for establishing a connection.
    //! \throws database_error
    //! \see connected(), connect()
    connection(const std::string& connection_string, int timeout = 5);

    //! \brief Automatically disconnects from the database and frees all associated resources.
    ~connection() throw();

    //! \brief Create new connection object and immediately connect to the given data source.
    //! \param dsn The name of the data source.
    //! \param user The username for authenticating to the data source.
    //! \param pass The password for authenticating to the data source.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected()
    void connect(const std::string& dsn, const std::string& user, const std::string& pass, int timeout = 5);

    //! \brief Create new connection object and immediately connect using the given connection string.
    //! \param connection_string The connection string for establishing a connection.
    //! \param timeout The number in seconds before connection timeout.
    //! \throws database_error
    //! \see connected()
    void connect(const std::string& connection_string, int timeout = 5);

    //! \brief Returns true if connected to the database.
    bool connected() const;

    //! \brief Disconnects from the database, but maintains environment and handle resources.
    void disconnect() throw();

    //! \brief Returns the number of transactions currently held for this connection.
    std::size_t transactions() const;

    //! \brief Returns the native ODBC database connection handle.
    HDBC native_dbc_handle() const;

    //! \brief Returns the native ODBC environment handle.
    HDBC native_evn_handle() const;

    //! \brief Returns the name of the ODBC driver.
    //! \throws database_error
    std::string driver_name() const;

private:
    connection(const connection&); // not defined
    connection& operator=(const connection&); // not defined

private:
    friend class nanodbc::transaction;

private:
    HENV env_;
    HDBC conn_;
    bool connected_;
    std::size_t transactions_;
    bool rollback_; // if true, this connection is marked for eventual transaction rollback
};

//! \brief A resource for managing transaction commits and rollbacks.
//!
//! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
//! \note transactions are non-copyable.
class transaction
{
public:
    //! \brief Begin a transaction on the given connection object.
    //! \post Operations that modify the database must now be committed before taking effect.
    //! \throws database_error
    explicit transaction(connection& conn);

    //! \brief If this transaction has not been committed, will will rollback any modifying operations.
    ~transaction() throw();

    //! \brief Marks this transaction for commit.
    //! \throws database_error
    void commit();

    //! \brief Marks this transaction for rollback.
    void rollback() throw();

private:
    transaction(const transaction&); // not defined
    transaction& operator=(const transaction&); // not defined

private:
    connection& conn_;
    bool committed_;
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
    unsigned long rowset_size() const;

    //! \brief Returns the number of rows affected by the request or –1 if the number of affected rows is not available.
    //! \throws database_error
    long affected_rows() const;

    //! \brief Returns the number of rows in the current rowset or 0 if the number of rows is not available.
    //! \throws database_error
    long rows() const;

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
    bool move(unsigned long row);

    //! \brief Skips a number of rows and then fetches the resulting row in the current result set.
    //! \return true if there are results or false otherwise.
    //! \throws database_error
    bool skip(unsigned long rows);

    //! \brief Returns the row position in the current result set.
    unsigned long position() const;

    //! \brief Returns true if there are no more results in the current result set.
    //! \throws database_error
    bool end() const;

    //! \brief Gets data from the given column in the selected row of the current rowset.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \param row If there are multiple rows in this rowset, get from the specified row.
    //! \throws database_error, index_range_error, type_incompatible_error
    template<class T>
    T get(short column, unsigned long row = 0) const
    {
        detail::bound_column& col = result_impl_get_bound_column(impl_, column, row);
        switch(col.ctype_)
        {
            case SQL_C_SSHORT: return (T)*(short*)(col.pdata_ + row * col.clen_);
            case SQL_C_USHORT: return (T)*(unsigned short*)(col.pdata_ + row * col.clen_);
            case SQL_C_SLONG: return (T)*(long*)(col.pdata_ + row * col.clen_);
            case SQL_C_ULONG: return (T)*(unsigned long*)(col.pdata_ + row * col.clen_);
            case SQL_C_FLOAT: return (T)*(float*)(col.pdata_ + row * col.clen_);
            case SQL_C_DOUBLE: return (T)*(double*)(col.pdata_ + row * col.clen_);
            case SQL_C_CHAR: if (!col.blob_) return detail::convert<T>((col.pdata_ + row * col.clen_));
        }
        throw type_incompatible_error();
    }

    //! \brief Returns true if and only if the given column in the selected row of the current rowset is null.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \param row If there are multiple rows in this rowset, get from the specified row.
    //! \throws database_error, index_range_error
    bool is_null(short column, unsigned long row = 0) const;

    //! \brief Returns the name of the specified column.
    //!
    //! Columns are numbered from left to right and 0-indexed.
    //! \param Column position. 
    //! \throws index_range_error
    std::string column_name(short column) const;

private:
    result(statement stmt, unsigned long rowset_size);

private:
    friend class nanodbc::detail::statement_impl;

private:
    detail::result_impl_ptr impl_;
};

template<>
inline std::string result::get<std::string>(short column, unsigned long row) const
{
    detail::bound_column& col = result_impl_get_bound_column(impl_, column, row);
    char buffer[1024];
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
    result execute_direct(connection& conn, const std::string& query, unsigned long batch_operations = 1);

    //! \brief Execute the previously prepared query now.
    //! \param batch_operations Numbers of rows to fetch per rowset, or the number of batch parameters to process.
    //! \throws database_error
    //! \return A result set object.
    //! \attention You will want to use transactions if you are doing batch operations because it will prevent auto commits from occurring after each individual operation is executed.
    //! \see open(), prepare(), execute(), result, transaction
    result execute(unsigned long batch_operations = 1);

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
    void bind_parameter(long param, const T& value)
    {
        detail::statement_bind_parameter_value(
            this
            , param
            , detail::sql_type_info<T>::ctype
            , detail::sql_type_info<T>::sqltype
            , (char*)&value
            , sizeof(value)
            , 1
            , false);
    }

    #ifndef DOXYGEN
    void bind_parameter(long param, const std::string& value)
    {
        detail::statement_bind_parameter_string(this, param, value);
    }
    #endif // DOXYGEN

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
            std::tr1::is_same<
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
        typename std::iterator_traits<InputIterator>::difference_type elements = distance(first, last);
        element_type* data = new element_type[elements];
        copy(first, last, data);
        detail::statement_bind_parameter_value(
            this
            , param
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
        std::tr1::is_same<
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
        size_type elements = distance(first, last);

        SQLULEN column_size;
        detail::describe_parameter_column_size(native_stmt_handle(), param, column_size);

        char* cdata = new char[elements * column_size];
        size_type row = 0;
        for(InputIterator i = first; i != last; ++i)
        {
            using namespace std; // promote strncpy() if it's not already
            strncpy(&cdata[row++ * column_size], std::string(*i).c_str(), column_size);
        }

        detail::statement_bind_parameter_value(
            this
            , param
            , detail::sql_type_info<std::string>::ctype
            , detail::sql_type_info<std::string>::sqltype
            , cdata
            , column_size
            , elements
            , true);
    }
    #endif // DOXYGEN

private:
    friend void nanodbc::detail::statement_bind_parameter_value(
        statement* me
        , long param
        , SQLSMALLINT ctype
        , SQLSMALLINT sqltype
        , char* data
        , std::size_t element_size
        , std::size_t elements
        , bool take_ownership);

    friend void nanodbc::detail::statement_bind_parameter_string(
        statement* me
        , long param
        , const std::string& string);

private:
    friend class nanodbc::detail::statement_impl;

private:
    detail::statement_impl_ptr impl_;
};

//! @}

} // namespace nanodbc

#endif // NANODBC_H
