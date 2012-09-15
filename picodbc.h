/*! \mainpage

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

Much of the code in this file was originally derived from TinyODBC.<br/>
TinyODBC is hosted at http://code.google.com/p/tiodbc/<br/>
Copyright (C) 2008 SqUe squarious@gmail.com<br/>
License: The MIT License<br/>

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
See http://www.codeguru.com/submission-guidelines.php for details.
*/

#ifndef PICODBC_H
#define PICODBC_H

#include <sql.h>
#include <sqlext.h>

#include <cassert>
#include <cstdio>
#include <cstring>
#include <map>
#include <stdexcept>
#include <string>
#include <tr1/cstdint>
#include <tr1/type_traits>
#include <vector>

//! \file picodbc.h The entirety of picodbc can be found within this one file.

//! \brief The entirety of picodbc can be found within this one namespace.
namespace picodbc
{

namespace detail
{
	// simple enable if utility taken from boost
	template <bool B, class T = void> struct enable_if_c { typedef T type; };
	template <class T> struct enable_if_c<false, T> { };
	template <bool B, class T = void> struct disable_if_c { typedef T type; };
	template <class T> struct disable_if_c<true, T> { };

	// easy way to check if a return code signifies success.
	inline bool success(RETCODE rc)
	{
		return rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO;
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
		SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
		SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, reinterpret_cast<void*>(SQL_OV_ODBC3), 0);
		SQLAllocHandle(SQL_HANDLE_DBC, env, &conn);	
	}

	// Tests if the given return data indicates NULL data.
	inline bool data_is_null(SQLLEN cbdata)
	{
		return (cbdata == SQL_NULL_DATA);
	}

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
	const char* const sql_type_info<short>::format = "%hd";

	template<>
	struct sql_type_info<unsigned short>
	{ 
		static const SQLSMALLINT ctype = SQL_C_USHORT; 
		static const SQLSMALLINT sqltype = SQL_SMALLINT;	
		static const char* const format; 
	};
	const char* const sql_type_info<unsigned short>::format = "%hu";

	template<>
	struct sql_type_info<long>
	{ 
		static const SQLSMALLINT ctype = SQL_C_SLONG; 
		static const SQLSMALLINT sqltype = SQL_INTEGER;	
		static const char* const format; 
	};
	const char* const sql_type_info<long>::format = "%ld";

	template<>
	struct sql_type_info<unsigned long>
	{ 
		static const SQLSMALLINT ctype = SQL_C_ULONG; 
		static const SQLSMALLINT sqltype = SQL_INTEGER;	
		static const char* const format; 
	};
	const char* const sql_type_info<unsigned long>::format = "%lu";

	template<>
	struct sql_type_info<int>
	{ 
		static const SQLSMALLINT ctype = SQL_C_SLONG; 
		static const SQLSMALLINT sqltype = SQL_INTEGER;	
		static const char* const format; 
	};
	const char* const sql_type_info<int>::format = "%d";

	template<>
	struct sql_type_info<unsigned int>
	{ 
		static const SQLSMALLINT ctype = SQL_C_ULONG; 
		static const SQLSMALLINT sqltype = SQL_INTEGER;	
		static const char* const format; 
	};
	const char* const sql_type_info<unsigned int>::format = "%u";

	template<>
	struct sql_type_info<float>
	{ 
		static const SQLSMALLINT ctype = SQL_C_FLOAT; 
		static const SQLSMALLINT sqltype = SQL_REAL;
		static const char* const format; 
	};
	const char* const sql_type_info<float>::format = "%f";

	template<>
	struct sql_type_info<double>
	{ 
		static const SQLSMALLINT ctype = SQL_C_DOUBLE; 
		static const SQLSMALLINT sqltype = SQL_DOUBLE;
		static const char* const format; 
	};
	const char* const sql_type_info<double>::format = "%ld";

	template<>
	struct sql_type_info<std::string>
	{ 
		static const SQLSMALLINT ctype = SQL_C_CHAR; 
		static const SQLSMALLINT sqltype = SQL_CHAR;
		static const char* const format; 
	};
	const char* const sql_type_info<std::string>::format = "%s";

	// Converts the given string to the given type T.
	template<class T>
	inline T convert(const std::string& s)
	{
		T value;
		std::sscanf(s.c_str(), sql_type_info<T>::format, &value);
		return value;
	}

	template<>
	inline std::string convert<std::string>(const std::string& s)
	{
		return s;
	}

	// Binds the given parameter number to the provided value.
	template<class T>
	inline const T& bind_parameter(HSTMT stmt, long param, const T& value, void* output)
	{
		std::memcpy(output, &value, sizeof(value));
		SQLLEN str_len_or_ind_ptr = 0;
		SQLBindParameter(
			stmt
			, param + 1
			, SQL_PARAM_INPUT
			, sql_type_info<T>::ctype
			, sql_type_info<T>::sqltype
			, 0
			, 0
			, (SQLPOINTER*)output
			, 0
			, &str_len_or_ind_ptr);
		return *reinterpret_cast<T*>(output);
	}
} // namespace detail

//! \brief Type incompatible.
class type_incompatible_error : public std::runtime_error
{
public:
	//! \brief Constructor.
	type_incompatible_error()
	: std::runtime_error("type incompatible") { }
	
	//! \brief Returns the explanatory string.
	const char* what() const throw()
	{
		return std::runtime_error::what();
	}
};

//! \brief Accessed NULL data.
class null_access_error : public std::runtime_error
{
public:
	//! \brief Constructor.
	null_access_error()
	: std::runtime_error("null access") { }
	
	//! \brief Returns the explanatory string.
	const char* what() const throw()
	{
		return std::runtime_error::what();
	}
};

//! \brief Index out of range.
class index_range_error : public std::runtime_error
{
public:
	//! \brief Constructor.
	index_range_error()
	: std::runtime_error("index out of range") { }
	
	//! \brief Returns the explanatory string.
	const char* what() const throw()
	{
		return std::runtime_error::what();
	}
};

//! \brief General database error.
class database_error : public std::runtime_error
{
public:
	//! \brief Creates a runtime_error with a message describing the last ODBC error generated for the given handle and handle_type.
	//! \param handle The native ODBC statement or connection handle.
	//! \param handle_type The native ODBC handle type code for the given handle.
	//! \param info Additional information that will be appended to the beginning of the error message.
	explicit database_error(SQLHANDLE handle, SQLSMALLINT handle_type, const std::string& info = "")
	: std::runtime_error(info + detail::last_error(handle, handle_type)) { }

	//! \brief Returns the explanatory string.
	const char* what() const throw()
	{
		return std::runtime_error::what();
	}
};

// We should use PICODBC_THROW_DATABASE_ERROR() to throw database_errors so that we provide additional information like file and line number.
#define PICODBC_STRINGIZE_I(text) #text
#define PICODBC_STRINGIZE(text) PICODBC_STRINGIZE_I(text)
#define PICODBC_THROW_DATABASE_ERROR(handle, handle_type) throw database_error(handle, handle_type, __FILE__ ":" PICODBC_STRINGIZE(__LINE__) ": ")

//! \brief Manages and encapsulates ODBC resources such as the connection and environment handles.
//!
//! \see connection
//! \note connections are non-copyable.
class connection
{
public:
	//! \brief Create new connection object, initially not connected.
	connection()
	: env_(NULL)
	, conn_(NULL)
	, connected_(false)
	, transactions_(0)
	, rollback_(false)
	{
		detail::allocate_handle(env_, conn_);
	}

	//! \brief Create new connection object and immediately connect to the given data source.
	//! \param dsn The name of the data source.
	//! \param user The username for authenticating to the data source.
	//! \param pass the password for authenticating to the data source.
	//! \throws database_error
	//! \see connected(), connect()
	connection(const std::string& dsn, const std::string& user, const std::string& pass, int timeout = 5)
	: env_(NULL)
	, conn_(NULL)
	, connected_(false)
	, transactions_(0)
	, rollback_(false)
	{
		detail::allocate_handle(env_, conn_);
		connect(dsn, user, pass, timeout);
	}

	//! \brief Create new connection object and immediately connect using the given connection string.
	//! \param connection_string The connection string for establishing a connection.
	//! \throws database_error
	//! \see connected(), connect()
	connection(const std::string& connection_string, int timeout = 5)
	: env_(NULL)
	, conn_(NULL)
	, connected_(false)
	, transactions_(0)
	, rollback_(false)
	{
		detail::allocate_handle(env_, conn_);
		connect(connection_string, timeout);
	}

	//! \brief Automatically disconnects from the database and frees all associated resources.
	~connection()
	{
		disconnect();
		SQLFreeHandle(SQL_HANDLE_DBC, conn_);
		SQLFreeHandle(SQL_HANDLE_ENV, env_);
	}

	//! \brief Create new connection object and immediately connect to the given data source.
	//! \param dsn The name of the data source.
	//! \param user The username for authenticating to the data source.
	//! \param pass the password for authenticating to the data source.
	//! \throws database_error
	//! \see connected()
	void connect(const std::string& dsn, const std::string& user, const std::string& pass, int timeout = 5)
	{
		disconnect();
		SQLFreeHandle(SQL_HANDLE_DBC, conn_);
		SQLAllocHandle(SQL_HANDLE_DBC, env_, &conn_);
		SQLSetConnectAttr(conn_, SQL_LOGIN_TIMEOUT, reinterpret_cast<SQLPOINTER*>(timeout), 0);
		RETCODE rc = SQLConnect(
			conn_
			, (SQLCHAR*)dsn.c_str(), SQL_NTS
			, user.empty() ? (SQLCHAR*)user.c_str() : NULL, SQL_NTS
			, pass.empty() ? (SQLCHAR*)pass.c_str() : NULL, SQL_NTS);
		connected_ = detail::success(rc);
		if (!connected_)
			PICODBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
	}

	//! \brief Create new connection object and immediately connect using the given connection string.
	//! \param connection_string The connection string for establishing a connection.
	//! \throws database_error
	//! \see connected()
	void connect(const std::string& connection_string, int timeout = 5)
	{
		disconnect();
		SQLFreeHandle(SQL_HANDLE_DBC, conn_);
		SQLAllocHandle(SQL_HANDLE_DBC, env_, &conn_);
		SQLCHAR dsn[1024];
		SQLSMALLINT dsn_size = 0;
		SQLSetConnectAttr(conn_, SQL_LOGIN_TIMEOUT, reinterpret_cast<SQLPOINTER*>(timeout), 0);
		RETCODE rc = SQLDriverConnect(
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

	//! \brief Returns true if connected to the database.
	bool connected() const
	{
		return connected_;
	}

	//! \brief Disconnects from the database, but maintains environment and handle resources.
	void disconnect()
	{
		if(connected())
			SQLDisconnect(conn_);
		connected_ = false;
	}

	//! \brief Returns the number of transactions currently held for this connection.
	std::size_t transactions() const
	{
		return transactions_;
	}

	//! \brief Returns the native ODBC database connection handle.
	HDBC native_dbc_handle() const
	{
		return conn_;
	}

	//! \brief Returns the native ODBC environment handle.
	HDBC native_evn_handle() const
	{
		return env_;
	}

private:
	connection(const connection&); // not defined
	connection& operator=(const connection&); // not defined

private:
	friend class transaction;
	HENV env_;
	HDBC conn_;
	bool connected_;
	std::size_t transactions_;
	bool rollback_; // if true, this connection is marked for eventual transaction rollback
};

//! \brief A resource for managing transaction commits and rollbacks.
//!
//! \see transaction
//! \not transactions are non-copyable.
class transaction
{
public:
	//! \brief Begin a transaction on the given connection object.
	//! \post Operations that modify the database must now be committed before taking effect.
	//! \throws database_error
	explicit transaction(connection& conn)
	: conn_(conn)
	, committed_(false)
	{
		if(conn_.transactions_ == 0 && conn_.connected())
		{
			SQLRETURN rc = SQLSetConnectAttr(
				conn_.native_dbc_handle()
				, SQL_ATTR_AUTOCOMMIT
				, static_cast<SQLPOINTER>(SQL_AUTOCOMMIT_OFF)
				, SQL_IS_UINTEGER);
			if (!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
		}
		++conn_.transactions_;
	}

	//! \brief If this transaction has not been committed, will will rollback any modifying operations.
	//! \throws database_error
	~transaction()
	{
		if(!committed_)
		{
			conn_.rollback_ = true;
			--conn_.transactions_;
		}

		if(conn_.transactions_ == 0 && conn_.rollback_ && conn_.connected())
		{
			SQLRETURN rc = SQLEndTran(SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_ROLLBACK);
			if (!detail::success(rc))
				throw database_error(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
			conn_.rollback_ = false;
			rc = SQLSetConnectAttr(
				conn_.native_dbc_handle()
				, SQL_ATTR_AUTOCOMMIT
				, reinterpret_cast<SQLPOINTER>(SQL_AUTOCOMMIT_ON)
				, SQL_IS_UINTEGER);
			if (!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
		}
	}

	//! \brief Marks this transaction for commit.
	void commit() throw()
	{
		if(committed_)
			return;
		committed_ = true;
		if((--conn_.transactions_) == 0 && conn_.connected())
			SQLEndTran(SQL_HANDLE_DBC, conn_.native_dbc_handle(), SQL_COMMIT);
	}

	//! \brief Marks this transaction for rollback.
	void rollback() throw()
	{
		if(committed_)
			return;
		conn_.rollback_ = true;
	}

private:
	transaction(const transaction&); // not defined
	transaction& operator=(const transaction&); // not defined

private:
	connection& conn_;
	bool committed_;
};

class statement;

namespace detail
{
	class param_type
	{
	public:
		~param_type()
		{

		}

	private:
		param_type(HSTMT stmt, long param)
		: stmt_(stmt)
		, param_(param)
		{

		}

		param_type(const param_type& rhs)
		: stmt_(rhs.stmt_)
		, param_(rhs.param_)
		{

		}

		param_type& operator=(param_type rhs)
		{
			swap(rhs);
			return *this;
		}

		void swap(param_type& rhs)
		{
			using std::swap;
			swap(stmt_, rhs.stmt_);
			swap(param_, rhs.param_);
		}

		template<class T>
		const T& set(const T& value)
		{
			return bind_parameter(stmt_, param_, value, value_buffer_);
		}

		const std::string& set(const std::string& str)
		{
			string_buffer_ = str;
			string_buffer_len_ = SQL_NTS;
			RETCODE rc = SQLBindParameter(
				stmt_
				, param_ + 1
				, SQL_PARAM_INPUT
				, detail::sql_type_info<std::string>::ctype
				, detail::sql_type_info<std::string>::sqltype
				, (SQLUINTEGER)string_buffer_.size()
				, 0
				, (SQLPOINTER*)string_buffer_.c_str()
				, (SQLLEN)string_buffer_.size() + 1
				, &string_buffer_len_);
			if (!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
			return string_buffer_;
		}

	private:
		friend class picodbc::statement;
		HSTMT stmt_;
		long param_;
		std::string::value_type value_buffer_[512];
		std::string string_buffer_;
		SQLLEN string_buffer_len_;
	};

	class column_type
	{
	public:
		~column_type()
		{
			delete[] pdata;
		}

	private:
		column_type()
		: name()
		, sqltype(0)
		, sqlsize(0)
		, scale(0)
		, ctype(0)
		, clen(0)
		, blob(false)
		, cbdata(0)
		, pdata(NULL)
		{

		}

	private:
		friend class picodbc::statement;
		std::string name;
		SQLSMALLINT sqltype;
		SQLULEN sqlsize;
		SQLSMALLINT scale;
		SQLSMALLINT ctype;
		SQLSMALLINT clen;
		bool blob;
		long cbdata;
		std::string::value_type* pdata;
	};
}

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

//! \brief Represents a statement on the database.
//!
//! \see statement
//! \note statements are non-copyable.
class statement
{
private:
	typedef std::map<long, detail::param_type*> params_type;
	typedef std::vector<detail::column_type> columns_type;

public:
	//! \brief Creates a new un-prepared statement.
	//! \see execute(), execute_direct(), open(), prepare()
	statement()
	: stmt_(NULL)
	, open_(false)
	{

	}

	//! \brief Constructs and prepares a statement using the given connection and query.
	//! \param conn The connection to use.
	//! \param stmt The SQL query statement.
	//! \see execute(), execute_direct(), open(), prepare()
	statement(connection& conn, const std::string& stmt)
	: stmt_(NULL)
	, open_(false)
	{
		prepare(conn, stmt);
	}

	//! \brief Closes the statement.
	//! \see close()
	~statement()
	{
		before_move();
		close();
	}

	//! \brief Creates a statement for the given connection.
	//! \param conn The connection where the statement will be executed.
	//! \throws database_error
	void open(connection& conn)
	{
		close();
		RETCODE rc = SQLAllocHandle(SQL_HANDLE_STMT, conn.native_dbc_handle(), &stmt_);
		open_ = detail::success(rc);
		if (!open_)
		{
			stmt_ = NULL;
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		}
	}

	//! \brief Returns true if connection is open.
	bool open() const
	{
		return open_;
	}

	//! \brief Returns the native ODBC statement handle.
	HDBC native_stmt_handle() const
	{
		return stmt_;
	}

	//! \brief Closes the statement and frees all associated resources.
	void close()
	{
		if(!open())
			return;
		open_ = false;
		for(params_type::iterator i = params_.begin(), end = params_.end(); i != end; ++i)
			delete i->second;
		params_.clear();
		free_results();
		SQLCancel(stmt_);
		SQLFreeHandle(SQL_HANDLE_STMT, stmt_);
		stmt_ = NULL;
	}

	//! \brief Opens and prepares the given statement to execute on the given connection.
	//! \param conn The connection where the statement will be executed.
	//! \param stmt The SQL query that will be executed.
	//! \see open()
	//! \throws database_error
	void prepare(connection& conn, const std::string& stmt)
	{
		open(conn);
		RETCODE rc = SQLPrepare(stmt_, (SQLCHAR*)stmt.c_str(), SQL_NTS);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Immediately opens, prepares, and executes the given query directly on the given connection.
	//! \param conn The connection where the statement will be executed.
	//! \param stmt The SQL query that will be executed.
	//! \see open(), prepare(), execute()
	//! \throws database_error
	void execute_direct(connection& conn, const std::string& query)
	{
		open(conn);
		RETCODE rc = SQLExecDirect(stmt_, (SQLCHAR*)query.c_str(), SQL_NTS);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		auto_bind();
	}

	//! \brief Execute the previously prepared query now.
	//! \throws database_error
	void execute()
	{
		if(!open())
			return;
		RETCODE rc = SQLExecute(stmt_);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		auto_bind();
	}

	//! \brief Returns the number of affected rows or rows in the current result set.
	//! \throws database_error
	long rows() const
	{
		SQLLEN rows;
		RETCODE rc = SQLRowCount(stmt_, &rows);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return rows;
	}

	//! \brief Returns the number of columns in the current result set.
	//! \throws database_error
	short columns() const
	{
		SQLSMALLINT cols;
		RETCODE rc = SQLNumResultCols(stmt_, &cols);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return cols;
	}

	//! \brief Fetches the first row in the current result set.
	//! \return true if there are more results or false otherwise.
	//! \throws database_error
	bool first()
	{
		return fetch(0, SQL_FETCH_FIRST);
	}

	//! \brief Fetches the last row in the current result set.
	//! \return true if there are more results or false otherwise.
	//! \throws database_error
	bool last()
	{
		return fetch(0, SQL_FETCH_LAST);
	}

	//! \brief Fetches the next row in the current result set.
	//! \return true if there are more results or false otherwise.
	//! \throws database_error
	bool next()
	{
		return fetch(0, SQL_FETCH_NEXT);
	}

	//! \brief Fetches the prior row in the current result set.
	//! \return true if there are more results or false otherwise.
	//! \throws database_error
	bool prior()
	{
		return fetch(0, SQL_FETCH_PRIOR);
	}

	//! \brief Moves to and fetches the specified row in the current result set.
	//! \return true if there are results or false otherwise.
	//! \throws database_error
	bool move(unsigned long row)
	{
		return fetch(row, SQL_FETCH_ABSOLUTE);
	}

	//! \brief Skips a number of rows and then fetches the resulting row in the current result set.
	//! \return true if there are results or false otherwise.
	//! \throws database_error
	bool skip(unsigned long rows)
	{
		return fetch(rows, SQL_FETCH_RELATIVE);
	}

	//! \brief Returns the current position in the current result set, or -1 on error.
	unsigned long position() const
	{
		SQLULEN pos;
		RETCODE rc = SQLGetStmtAttr(
			stmt_
			, SQL_ATTR_ROW_NUMBER
			, &pos
			, SQL_IS_UINTEGER
			, NULL);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return pos;
	}

	//! \brief Returns true if there are no more results in the current result set.
	//! \throws database_error
	bool end() const
	{
		return (position() > static_cast<unsigned long>(rows()));
	}

	//! \brief Frees the current result set.
	void free_results()
	{
		if(open())
			SQLCloseCursor(stmt_);
	}

	//! \brief Binds the given value to the given parameter placeholder number in the prepared statement.
	//!
	//! If your prepared SQL query has any ? placeholders, this is how you bind values to them.
	//! Placeholder numbers count from left to right and are 0-indexed.
	//! \param param Placeholder position.
	//! \param value Value to substitute into placeholder.
	//! \return The bound value.
	//! \throws database_error
	template<class T>
	const T& bind_parameter(long param, const T& value)
	{
		if(!params_.count(param))
			params_[param] = new class detail::param_type(stmt_, param);
		return params_[param]->set(value);
	}

	//! \brief Binds the given column to the supplied output parameter.
	//!
	//! A statement must be executed before attempting to bind, otherwise index_range_error will be thrown.
	//! Each call to next() will fill the output parameter with the next value.
	//! Columns are numbered from left to right and 0-indexed.
	//! \param column Column position.
	//! \param output Bound storage value.
	//! \note You can not bind a std::string to a column, use bind_column_buffer() instead.
	//! \see bind_column_buffer
	//! \throws database_error, index_range_error
	template<class T>
	#ifdef DOXYGEN
		void
	#else
		typename detail::disable_if_c<std::tr1::is_same<T, std::string>::value, void>::type
	#endif
	bind_column(short column, T& output)
	{
		release_bind(column);
		columns_[column].clen = sizeof(T);
		SQLLEN cbdata = 0;
		RETCODE rc = SQLBindCol(
			stmt_
			, column + 1
			, detail::sql_type_info<T>::ctype
			, &output
			, columns_[column].clen
			, &columns_[column].cbdata);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Binds the given column to the supplied output character buffer.
	//!
	//! A statement must be executed before attempting to bind, otherwise index_range_error will be thrown.
	//! Each call to next() will fill the output buffer with the next value.
	//! Columns are numbered from left to right and 0-indexed.
	//! \param column Column position.
	//! \param output Bound output buffer.
	//! \param length Size of output buffer.
	//! \see bind_column
	//! \throws database_error, index_range_error
	void bind_column_buffer(short column, char* buffer, long length)
	{
		release_bind(column);
		columns_[column].clen = length;
		columns_[column].ctype = detail::sql_type_info<std::string>::ctype;
		RETCODE rc = SQLBindCol(
			stmt_
			, column + 1
			, columns_[column].ctype
			, buffer
			, columns_[column].clen
			, &columns_[column].cbdata);

		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Resets all currently bound parameters.
	void reset_parameters()
	{
		if(!open())
			return;
		SQLFreeStmt(stmt_, SQL_RESET_PARAMS);
	}

	//! \brief Gets data from the given column in the selected row of the current result set.
	//!
	//! Columns are numbered from left to right and 0-indexed.
	//! \param Column position. 
	//! \throws database_error, index_range_error, type_incompatible_error
	template<class T>
	T get(short column)
	{
		if(column >= columns_.size())
			throw index_range_error();
		if(is_null(column))
			throw null_access_error();
		const detail::column_type& col = columns_[column];
		switch(col.ctype)
		{
			case SQL_C_SSHORT:
				return (T)*(short*)col.pdata;
			case SQL_C_USHORT:
				return (T)*(unsigned short*)col.pdata;
			case SQL_C_SLONG:
				return (T)*(long*)col.pdata;
			case SQL_C_ULONG:
				return (T)*(unsigned long *)col.pdata;
			case SQL_C_FLOAT:
				return (T)*(float*)col.pdata;
			case SQL_C_DOUBLE:
				return (T)*(double*)col.pdata;
			case SQL_C_CHAR:
				if (!col.blob)
					return detail::convert<T>(columns_[column].pdata);
		}
		throw type_incompatible_error();
	}

	//! \brief Returns true if and only if the given column in the selected row of the current results set is NULL.
	//!
	//! Columns are numbered from left to right and 0-indexed.
	//! \param Column position. 
	//! \throws database_error, index_range_error
	bool is_null(short column)
	{
		if(column >= columns_.size())
			throw index_range_error();
		return detail::data_is_null(columns_[column].cbdata);
	}

	//! \brief Returns the name of the specified column.
	//!
	//! Columns are numbered from left to right and 0-indexed.
	//! \param Column position. 
	//! \throws index_range_error
	std::string column_name(short column)
	{
		if(column >= columns_.size())
			throw index_range_error();
		return columns_[column].name;
	}

private:
	statement(const statement&); // not defined
	statement& operator=(const statement&); // not defined

	void before_move()
	{
		for (std::size_t i = 0; i < columns_.size(); ++i)
		{
			columns_[i].cbdata = 0;
			if(columns_[i].blob && columns_[i].pdata)
				release_bind(i);
		}
	}

	bool fetch(unsigned long rows, SQLUSMALLINT orientation)
	{
		if(!open())
			return false;
		SQLULEN row_out = 0;
		SQLUSMALLINT status;
		before_move();
		RETCODE rc = SQLExtendedFetch(stmt_, orientation, rows, &row_out, &status);
		if (rc == SQL_NO_DATA)
			return false;
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return true;
	}

	void release_bind(short column)
	{
		if(column >= columns_.size())
			throw index_range_error();
		delete[] columns_[column].pdata;
		columns_[column].pdata = 0;
		columns_[column].clen = 0;
	}

	void auto_bind()
	{
		columns_type().swap(columns_);

		SQLSMALLINT n_columns = 0;
		RETCODE rc = SQLNumResultCols(stmt_, &n_columns);

		if(!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		if(n_columns < 1)
			return;

		columns_.reserve(n_columns);

		typedef std::string::value_type char_type;
		SQLCHAR column_name[1024];
		SQLSMALLINT sqltype, scale, nullable, len;
		SQLULEN sqlsize;

		for(SQLSMALLINT i = 0; i < n_columns; ++i)
		{
			rc = SQLDescribeCol(
				stmt_
				, i + 1
				, column_name
				, sizeof(column_name)
				, &len
				, &sqltype
				, &sqlsize
				, &scale
				, &nullable);

			if(!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);

			detail::column_type col;
			col.name = reinterpret_cast<char*>(column_name);
			col.sqltype = sqltype;
			col.sqlsize = sqlsize;
			col.scale = scale;

			switch(col.sqltype)
			{
				case SQL_BIT:
				case SQL_TINYINT:
				case SQL_SMALLINT:
				case SQL_INTEGER:
					col.ctype = SQL_C_LONG;
					col.clen = 4;
					break;
				case SQL_DOUBLE:
				case SQL_FLOAT:
				case SQL_NUMERIC:
				case SQL_DECIMAL:
				case SQL_REAL:
					col.ctype = SQL_C_DOUBLE;
					col.clen = 8;
					break;
				case SQL_DATE:
				case SQL_TYPE_DATE:
					col.ctype = SQL_C_DATE;
					col.clen = sizeof(date_type);
					break;
				case SQL_TIMESTAMP:
				case SQL_TYPE_TIMESTAMP:
					col.ctype = SQL_C_TIMESTAMP;
					col.clen = sizeof(timestamp_type);
					break;
				case SQL_CHAR:
				case SQL_VARCHAR:
					col.ctype = SQL_C_CHAR;
					col.clen = col.sqlsize + 1;
					break;
				case SQL_LONGVARCHAR:
					col.ctype = SQL_C_CHAR;
					col.blob = true;
					col.clen = 0;
					break;
				case SQL_BINARY:
				case SQL_VARBINARY:
					col.ctype = SQL_C_BINARY;
					col.clen = col.sqlsize + 1;
					break;
				case SQL_LONGVARBINARY:
					col.ctype = SQL_C_BINARY;
					col.blob = true;
					col.clen = 0;
					break;
				default:
					col.ctype = detail::sql_type_info<std::string>::ctype;
					col.clen = 128 * sizeof(char_type);
					break;
			}

			columns_.push_back(col);
		}

		for(SQLSMALLINT i = 0; i < n_columns; ++i)
		{
			detail::column_type& col = columns_[i];
			if(col.blob)
			{
				rc = SQLBindCol(stmt_, i + 1, col.ctype, 0, 0, &col.cbdata);
			}
			else
			{
				col.pdata = new char_type[col.clen];
				rc = SQLBindCol(stmt_, i + 1, col.ctype, col.pdata, col.clen, &col.cbdata);
			}
			if(!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		}
	}

private:
	HSTMT stmt_;
	bool open_;
	params_type params_;
	columns_type columns_;
};

template<>
inline std::string statement::get<std::string>(short column)
{
	if(column >= columns_.size())
		throw index_range_error();
	if(is_null(column))
		throw null_access_error();
	const detail::column_type& col = columns_[column];
    char buffer[1024];
	switch(col.ctype)
	{
		case SQL_C_CHAR:
		case SQL_C_GUID:
		case SQL_C_BINARY:
			if(col.blob)
				// load_blob(column);
				throw std::runtime_error("blob not implemented yet"); // #T
			return col.pdata;

		case SQL_C_LONG:
			if(std::snprintf(buffer, sizeof(buffer), "%ld", *(long*)col.pdata) != 1)
				throw type_incompatible_error();
			return buffer;

		case SQL_C_DOUBLE:
			if(std::snprintf(buffer, sizeof(buffer), "%lf", *(double*)col.pdata) != 1)
				throw type_incompatible_error();
			return buffer;

		case SQL_C_DATE:
			throw std::runtime_error("date not implemented yet"); // #T

		case SQL_C_TIMESTAMP:
			throw std::runtime_error("timestamp not implemented yet"); // #T
	}
	throw type_incompatible_error();
}

#undef PICODBC_THROW_DATABASE_ERROR
#undef PICODBC_STRINGIZE
#undef PICODBC_STRINGIZE_I

} // namespace picodbc

#endif // PICODBC_H
