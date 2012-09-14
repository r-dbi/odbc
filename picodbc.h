/*! \mainpage

\verbatim
Copyright (C) 2012 Amy Troschinetz <amy [at] lexicalunit [dot] com>

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
\endverbatim

\note
Much of the code in this file was originally derived from TinyODBC.<br/>
TinyODBC is hosted at http://code.google.com/p/tiodbc/<br/>
Copyright (C) 2008 SqUe <squarious [at] gmail [dot] com><br/>
License: The MIT License<br/>

\note
Transaction support was based on the implementation in SimpleDB: C++ ODBC database API.<br/>
SimpleDB is hosted at http://simpledb.sourceforge.net<br/>
Copyright (C) 2006 Eminence Technology Pty Ltd<br/>
Copyright (C) 2008-2010,2012 Russell Kliese <russell [at] kliese [dot] id [dot] au><br/>
License: GNU Lesser General Public version 2.1<br/>

\note
Some improvements and features are based on The Python ODBC Library.<br/>
The Python ODBC Library is hosted at http://code.google.com/p/pyodbc/<br/>
License: The MIT License<br/>
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
#include <tr1/type_traits>

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

	// Tests if the given db_data indicates NULL data.
	inline bool is_null(SQLLEN cb_data)
	{
		return (cb_data == SQL_NULL_DATA || cb_data < 0);
	}

	// A utility for calculating the ctype, sqltype, and format specifiers for the given type T.
	template<class T>
	struct sql_type_info { };

	template<>
	struct sql_type_info<short> { static const SQLSMALLINT ctype = SQL_C_SSHORT; static const SQLSMALLINT sqltype = SQL_SMALLINT; 
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<short>::format = "%hd";
	const wchar_t* const sql_type_info<short>::wformat = L"%hd";

	template<>
	struct sql_type_info<unsigned short> { static const SQLSMALLINT ctype = SQL_C_USHORT; static const SQLSMALLINT sqltype = SQL_SMALLINT;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<unsigned short>::format = "%hu";
	const wchar_t* const sql_type_info<unsigned short>::wformat = L"%hu";

	template<>
	struct sql_type_info<long> { static const SQLSMALLINT ctype = SQL_C_SLONG; static const SQLSMALLINT sqltype = SQL_INTEGER;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<long>::format = "%ld";
	const wchar_t* const sql_type_info<long>::wformat = L"%ld";

	template<>
	struct sql_type_info<unsigned long> { static const SQLSMALLINT ctype = SQL_C_ULONG; static const SQLSMALLINT sqltype = SQL_INTEGER;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<unsigned long>::format = "%lu";
	const wchar_t* const sql_type_info<unsigned long>::wformat = L"%lu";

	template<>
	struct sql_type_info<int> { static const SQLSMALLINT ctype = SQL_C_SLONG; static const SQLSMALLINT sqltype = SQL_INTEGER;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<int>::format = "%d";
	const wchar_t* const sql_type_info<int>::wformat = L"%d";

	template<>
	struct sql_type_info<unsigned int> { static const SQLSMALLINT ctype = SQL_C_ULONG; static const SQLSMALLINT sqltype = SQL_INTEGER;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<unsigned int>::format = "%u";
	const wchar_t* const sql_type_info<unsigned int>::wformat = L"%u";

	template<>
	struct sql_type_info<float> { static const SQLSMALLINT ctype = SQL_C_FLOAT; static const SQLSMALLINT sqltype = SQL_REAL;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<float>::format = "%f";
	const wchar_t* const sql_type_info<float>::wformat = L"%f";

	template<>
	struct sql_type_info<double> { static const SQLSMALLINT ctype = SQL_C_DOUBLE; static const SQLSMALLINT sqltype = SQL_DOUBLE;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<double>::format = "%ld";
	const wchar_t* const sql_type_info<double>::wformat = L"%ld";

	template<>
	struct sql_type_info<std::string> { static const SQLSMALLINT ctype = SQL_C_CHAR; static const SQLSMALLINT sqltype = SQL_CHAR;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<std::string>::format = "%s";
	const wchar_t* const sql_type_info<std::string>::wformat = L"%s";

	template<>
	struct sql_type_info<std::wstring> { static const SQLSMALLINT ctype = SQL_C_WCHAR; static const SQLSMALLINT sqltype = SQL_CHAR;
		static const char* const format; static const wchar_t* const wformat; };
	const char* const sql_type_info<std::wstring>::format = "%ls";
	const wchar_t* const sql_type_info<std::wstring>::wformat = L"%ls";

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

	template<class T>
	inline T convert(const std::wstring& s)
	{
		T value;
		std::swscanf(s.c_str(), sql_type_info<T>::wformat, &value);
		return value;
	}

	template<>
	inline std::wstring convert<std::wstring>(const std::wstring& s)
	{
		return s;
	}

	// Binds the given column as an input parameter, the parameter value is written into the given output buffer.
	template<class T>
	inline const T& bind_param(HSTMT stmt, long column, const T& value, void* output)
	{
		std::memcpy(output, &value, sizeof(value));
		SQLLEN str_len_or_ind_ptr = 0;
		SQLBindParameter(
			stmt
			, column + 1
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
//! For unicode operations use the wconnection variant, otherwise just connection.
//! \see connection, wconnection
//! \note connections are non-copyable.
template<class String>
class basic_connection
{
public:
	typedef String string_type;

public:
	//! \brief Create new connection object, initially not connected.
	basic_connection()
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
	basic_connection(const string_type& dsn, const string_type& user, const string_type& pass, int timeout = 5)
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
	basic_connection(const string_type& connection_string, int timeout = 5)
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
	~basic_connection()
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
	void connect(const string_type& dsn, const string_type& user, const string_type& pass, int timeout = 5)
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
	void connect(const string_type& connection_string, int timeout = 5)
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
			, dsn, sizeof(dsn) / sizeof(dsn[0])
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
	basic_connection(const basic_connection&); // not defined
	basic_connection& operator=(const basic_connection&); // not defined

private:
	template<class> friend class basic_transaction;
	HENV env_;
	HDBC conn_;
	bool connected_;
	std::size_t transactions_;
	bool rollback_; // if true, this connection is marked for eventual transaction rollback
};

//! \brief A resource for managing transaction commits and rollbacks.
//!
//! For unicode operations use the wtransaction variant, otherwise just transaction.
//! \see transaction, wtransaction
//! \not transactions are non-copyable.
template<class String>
class basic_transaction
{
public:
	typedef String string_type;

public:
	//! \brief Begin a transaction on the given connection object.
	//! \post Operations that modify the database must now be committed before taking effect.
	//! \throws database_error
	explicit basic_transaction(basic_connection<string_type>& conn)
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
	~basic_transaction()
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
	basic_transaction(const basic_transaction&); // not defined
	basic_transaction& operator=(const basic_transaction&); // not defined

private:
	basic_connection<string_type>& conn_;
	bool committed_;
};

template<class> class basic_statement;

namespace detail
{
	template<class String>
	class basic_param
	{
	private:
		typedef String string_type;

	private:
		basic_param(HSTMT stmt, long column)
		: stmt_(stmt)
		, column_(column)
		{

		}

		basic_param(const basic_param& rhs)
		: stmt_(rhs.stmt_)
		, column_(rhs.column_)
		{

		}

		~basic_param()
		{

		}

		basic_param& operator=(basic_param rhs)
		{
			swap(rhs);
			return *this;
		}

		void swap(basic_param& rhs)
		{
			using std::swap;
			swap(stmt_, rhs.stmt_);
			swap(column_, rhs.column_);
		}

		template<class T>
		const T& set(const T& value)
		{
			return bind_param(stmt_, column_, value, value_buffer_);
		}

		const string_type& set(const string_type& str)
		{
			string_buffer_ = str;
			string_buffer_len_ = SQL_NTS;
			RETCODE rc = SQLBindParameter(
				stmt_
				, column_ + 1
				, SQL_PARAM_INPUT
				, detail::sql_type_info<string_type>::ctype
				, detail::sql_type_info<string_type>::sqltype
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
		friend class picodbc::basic_statement<string_type>;
		HSTMT stmt_;
		long column_;
		typename string_type::value_type value_buffer_[512];
		string_type string_buffer_;
		SQLLEN string_buffer_len_;
	};

	// template<class String>
	// template<>
	// inline const std::string& basic_param<String>::set<String>(const String& str)
	// {
	// 	string_buffer_ = str;
	// 	string_buffer_len_ = SQL_NTS;
	// 	RETCODE rc = SQLBindParameter(
	// 		stmt_
	// 		, column_ + 1
	// 		, SQL_PARAM_INPUT
	// 		, detail::sql_type_info<String>::ctype
	// 		, detail::sql_type_info<String>::sqltype
	// 		, (SQLUINTEGER)string_buffer_.size()
	// 		, 0
	// 		, (SQLPOINTER*)string_buffer_.c_str()
	// 		, (SQLLEN)string_buffer_.size() + 1
	// 		, &string_buffer_len_);
	// 	if (!detail::success(rc))
	// 		PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	// 	return string_buffer_;
	// }
}

//! \brief Represents a statement on the database.
//!
//! For unicode operations use the wstatement variant, otherwise just statement.
//! \see statement, wstatement
//! \note statements are non-copyable.
template<class String>
class basic_statement
{
public:
	typedef String string_type;

private:
	typedef std::map<long, detail::basic_param<string_type>*> params_type;

private:
	template<class T>
	T get_from_cache(long column)
	{
		assert(cache_.count(column));
		return detail::convert<T>(cache_[column]);
	}

	template<class T>
	void get_direct(long column, bool error_on_null, T& value)
	{
		SQLLEN cb_needed;
		RETCODE rc = SQLGetData(stmt_, column + 1, detail::sql_type_info<T>::sqltype, &value, sizeof(value), &cb_needed);
		if(detail::is_null(cb_needed))
			null_[column] = 1;
		if(detail::is_null(cb_needed) && error_on_null)
			throw null_access_error();
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	void get_direct(long column, bool error_on_null, string_type& value)
	{
		SQLLEN cb_needed = 0;
		char small_buff[256];				
		RETCODE rc = SQLGetData(stmt_, column + 1, detail::sql_type_info<string_type>::ctype, small_buff, sizeof(small_buff), &cb_needed);
		if(detail::is_null(cb_needed))
			null_[column] = 1;
		if(detail::is_null(cb_needed) && error_on_null)
		{
			throw null_access_error();
		}
		else if(!detail::success(rc))
		{
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		}
		else if(detail::success(rc) && cb_needed < sizeof(small_buff))
		{
			value = small_buff;
		}
		else if(cb_needed > 0)
		{
			SQLLEN sz_buff = cb_needed + 1;
			typedef typename string_type::value_type char_type;
			char_type p_data[sz_buff];
			std::size_t offset = sizeof(small_buff) * sizeof(char_type) - 1;
			std::memcpy(p_data, small_buff, offset);
			rc = SQLGetData(stmt_, column + 1, detail::sql_type_info<string_type>::ctype, (char_type*)(p_data + offset), sz_buff - offset, &cb_needed);
	        if (!detail::success(rc))
				PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
			value = p_data;
		}
	}

public:
	//! \brief Creates a new un-prepared statement.
	//! \see execute(), execute_direct(), open(), prepare()
	basic_statement()
	: stmt_(NULL)
	, open_(false)
	, position_(-1)
	, rows_(-1)
	, columns_(-1)
	{

	}

	//! \brief Constructs and prepares a statement using the given connection and query.
	//! \param conn The connection to use.
	//! \param stmt The SQL query statement.
	//! \see execute(), execute_direct(), open(), prepare()
	basic_statement(basic_connection<string_type>& conn, const string_type& stmt)
	: stmt_(NULL)
	, open_(false)
	{
		prepare(conn, stmt);
	}

	//! \brief Closes the statement.
	//! \see close()
	~basic_statement()
	{
		close();
	}

	//! \brief Creates a statement for the given connection.
	//! \param conn The connection where the statement will be executed.
	//! \throws database_error
	void open(basic_connection<string_type>& conn)
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
	HDBC native_handle() const
	{
		return stmt_;
	}

	//! \brief Closes the statement and frees all associated resources.
	void close()
	{
		if(!open())
			return;
		open_ = false;
		for(typename params_type::iterator i = params_.begin(), end = params_.end(); i != end; ++i)
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
	void prepare(basic_connection<string_type>& conn, const string_type& stmt)
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
	void execute_direct(basic_connection<string_type>& conn, const string_type& query)
	{
		open(conn);
		RETCODE rc = SQLExecDirect(stmt_, (SQLCHAR*)query.c_str(), SQL_NTS);
		if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
	}

	//! \brief Returns the current position in the current result set, or -1 on error.
	long position() const
	{
		if(!open())
			return -1;
		return position_;
	}

	//! \brief Returns the number of affected rows or rows in the current result set, or -1 on error.
	long rows() const
	{
		if(!open())
			return -1;
		if(rows_ != -1)
			return rows_;
		SQLLEN rows = 0;
		RETCODE rc = SQLRowCount(stmt_, &rows);
		if(!detail::success(rc))
			return -1;
		return rows_ = rows;
	}

	//! \brief Returns the number of columns in the current result set, or -1 on error.
	long columns() const
	{
		if(!open())
			return -1;
		if(columns_ != -1)
			return columns_;
		SQLSMALLINT columns = 0;
		RETCODE rc = SQLNumResultCols(stmt_, &columns);
		if(!detail::success(rc))
			return -1;
		return columns_ = columns;
	}

	//! \brief Fetches the next row in the current result set.
	//! \return true if there are more results or false otherwise.
	//! \throws database_error
	bool next()
	{
		if(!open())
			return false;
		++position_;
		cache_.clear();
		null_.clear();
		RETCODE rc = SQLFetch(stmt_);
		if (rc == SQL_NO_DATA)
        	return false;
        if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return true;
	}

	//! \brief Returns true if there are no more results in the current result set.
	bool end() const
	{
		if(position() == -1 || rows() == -1)
			return true;
		return position() > rows();
	}

	//! \brief Frees the current result set.
	void free_results()
	{
		position_ = -1;
		rows_ = -1;
		columns_ = -1;
		if(open())
			SQLCloseCursor(stmt_);
	}

	//! \brief Binds the given value to the given column in the prepared statement.
	//!
	//! If your prepared SQL query has any ? placeholders, this is how you bind values to them.
	//! \throws database_error
	template<class T>
	const T& bind_value(long column, const T& value)
	{
		if(!params_.count(column))
			params_[column] = new class detail::basic_param<string_type>(stmt_, column);
		return params_[column]->set(value);
	}

	//! \brief Binds the given column to the supplied output parameter.
	//!
	//! Each call to next() will fill the output parameter with the next value.
	//! \note You can not bind a string_type to a column, use bind_column_str() instead.
	//! \see bind_column_str
	//! \throws database_error
	template<class T>
	#ifdef DOXYGEN
		void
	#else
		typename detail::disable_if_c<std::tr1::is_same<T, string_type>::value, void>::type
	#endif
	bind_column(long column, T& output)
	{
		SQLLEN cb_data = 0;
		RETCODE rc = SQLBindCol(stmt_, column + 1, detail::sql_type_info<T>::ctype, &output, sizeof(T), &cb_data);
        if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Binds the given column to the supplied output character buffer.
	//!
	//! Each call to next() will fill the output parameter with the next value.
	//! \note Unless you want to fetch string data you should use bind_column() instead.
	//! \see bind_column
	//! \throws database_error
	void bind_column_str(long column, typename string_type::value_type* output, typename string_type::size_type length)
	{
		SQLLEN cb_data = 0;
		RETCODE rc = SQLBindCol(stmt_, column + 1, detail::sql_type_info<string_type>::ctype, output, length, &cb_data);
        if (!detail::success(rc))
			PICODBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Resets all currently bound value parameters and bound columns.
	void reset_parameters()
	{
		if(!open())
			return;
		SQLFreeStmt(stmt_, SQL_RESET_PARAMS);
		SQLFreeStmt(stmt_, SQL_UNBIND);
	}

	//! \brief Gets data from the given column in the selected row of the current result set.
	//! \throws database_error
	template<class T>
	T get(long column)
	{
		if(null_.count(column))
			throw null_access_error();
		if(cache_.count(column))
			return get_from_cache<T>(column);
		T value;
		get_direct(column, true, value);
		return value;		
	}

	//! \brief Returns true if and only if the given column in the selected row of the current results set is NULL.
	//! \throws database_error
	bool is_null(long column)
	{
		string_type value;
		get_direct(column, false, value);
		cache_[column] = value;
		return null_.count(column);
	}

private:
	basic_statement(const basic_statement&); // not defined
	basic_statement& operator=(const basic_statement&); // not defined

private:
	HSTMT stmt_;
	bool open_;
	long position_;
	mutable long rows_;
	mutable long columns_;
	mutable std::map<long, string_type> cache_;
	mutable std::map<long, bool> null_;
	params_type params_;
};

#undef PICODBC_THROW_DATABASE_ERROR
#undef picoDBC_STRINGIZE
#undef picoDBC_STRINGIZE_I

typedef basic_connection<std::string> connection;		//!< Non-unicode connection.
typedef basic_transaction<std::string> transaction;		//!< Non-unicode transaction.
typedef basic_statement<std::string> statement;			//!< Non-unicode statment.

typedef basic_connection<std::wstring> wconnection;		//!< Unicode connection.
typedef basic_transaction<std::wstring> wtransaction;	//!< Unicode transaction.
typedef basic_statement<std::wstring> wstatement;		//!< Unicode statment.

} // namespace picodbc

#endif // PICODBC_H
