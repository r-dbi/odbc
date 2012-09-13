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

//! \file picodbc.h The entirety of picodbc can be found within this one file.

//! The entirety of picodbc can be found within this one namespace.
namespace picodbc
{

namespace detail
{
	// easy way to check if a return code signifies success.
	inline bool success(RETCODE rc)
	{
		return rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO;
	}

	// attempts to get the last ODBC error as a string.
	std::string last_error(SQLHANDLE handle, SQLSMALLINT handle_type)
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
	void allocate_handle(HENV& env, HDBC& conn)
	{
		SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
		SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, reinterpret_cast<void*>(SQL_OV_ODBC3), 0);
		SQLAllocHandle(SQL_HANDLE_DBC, env, &conn);	
	}

	// Tests if the given db_data indicates NULL data.
	bool is_null(SQLLEN cb_data)
	{
		return (cb_data == SQL_NULL_DATA || cb_data < 0);
	}

	// A utility for calculating the ctype, sqltype, and format specifier for the given type T.
	template<class T>
	struct sql_type_info { };

	template<>
	struct sql_type_info<short> { static const SQLSMALLINT ctype = SQL_C_SSHORT; static const SQLSMALLINT sqltype = SQL_SMALLINT; static const char* const format; };
	const char* const sql_type_info<short>::format = "%hd";

	template<>
	struct sql_type_info<unsigned short> { static const SQLSMALLINT ctype = SQL_C_USHORT; static const SQLSMALLINT sqltype = SQL_SMALLINT; static const char* const format; };
	const char* const sql_type_info<unsigned short>::format = "%hu";

	template<>
	struct sql_type_info<long> { static const SQLSMALLINT ctype = SQL_C_SLONG; static const SQLSMALLINT sqltype = SQL_INTEGER; static const char* const format; };
	const char* const sql_type_info<long>::format = "%ld";

	template<>
	struct sql_type_info<unsigned long> { static const SQLSMALLINT ctype = SQL_C_ULONG; static const SQLSMALLINT sqltype = SQL_INTEGER; static const char* const format; };
	const char* const sql_type_info<unsigned long>::format = "%lu";

	template<>
	struct sql_type_info<int> { static const SQLSMALLINT ctype = SQL_C_SLONG; static const SQLSMALLINT sqltype = SQL_INTEGER; static const char* const format; };
	const char* const sql_type_info<int>::format = "%d";

	template<>
	struct sql_type_info<unsigned int> { static const SQLSMALLINT ctype = SQL_C_ULONG; static const SQLSMALLINT sqltype = SQL_INTEGER; static const char* const format; };
	const char* const sql_type_info<unsigned int>::format = "%u";

	template<>
	struct sql_type_info<float> { static const SQLSMALLINT ctype = SQL_C_FLOAT; static const SQLSMALLINT sqltype = SQL_REAL; static const char* const format; };
	const char* const sql_type_info<float>::format = "%f";

	template<>
	struct sql_type_info<double> { static const SQLSMALLINT ctype = SQL_C_DOUBLE; static const SQLSMALLINT sqltype = SQL_DOUBLE; static const char* const format; };
	const char* const sql_type_info<double>::format = "%ld";

	template<>
	struct sql_type_info<std::string> { static const SQLSMALLINT ctype = SQL_C_CHAR; static const SQLSMALLINT sqltype = SQL_CHAR; static const char* const format; };
	const char* const sql_type_info<std::string>::format = "%s";

	// Converts the given string to the given type T.
	template<class T>
	T convert(const std::string& s)
	{
		T value;
		std::sscanf(s.c_str(), sql_type_info<T>::format, &value);
		return value;
	}

	// Binds the given column as an input parameter, the parameter value is written into the given output buffer.
	template<class T>
	const T& bind_param(HSTMT stmt, long column, const T& value, void* output)
	{
		std::memcpy(output, &value, sizeof(value));
		SQLLEN StrLenOrInPoint = 0;
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
			, &StrLenOrInPoint);
		return *(T*)output;
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

// We should use picoDBC_THROW_DATABASE_ERROR() to throw database_errors so that we provide additional information like file and line number.
#define picoDBC_STRINGIZE_I(text) #text
#define picoDBC_STRINGIZE(text) picoDBC_STRINGIZE_I(text)
#define picoDBC_THROW_DATABASE_ERROR(handle, handle_type) throw database_error(handle, handle_type, __FILE__ ":" picoDBC_STRINGIZE(__LINE__) ": ")

//! \brief Manages and encapsulates ODBC resources such as the connection and environment handles.
//! \note connection is non-copyable.
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
	//! vparam user The username for authenticating to the data source.
	//! \param pass the password for authenticating to the data source.
	//! \throws database_error
	//! \see connected(), connect()
	connection(const std::string& dsn, const std::string& user, const std::string& pass)
	: env_(NULL)
	, conn_(NULL)
	, connected_(false)
	, transactions_(0)
	, rollback_(false)
	{
		detail::allocate_handle(env_, conn_);
		connect(dsn, user, pass);
	}

	//! \brief Create new connection object and immediately connect using the given connection string.
	//! \param connection_string The connection string for establishing a connection.
	//! \throws database_error
	//! \see connected(), connect()
	connection(const std::string& connection_string)
	: env_(NULL)
	, conn_(NULL)
	, connected_(false)
	, transactions_(0)
	, rollback_(false)
	{
		detail::allocate_handle(env_, conn_);
		connect(connection_string);
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
	void connect(const std::string& dsn, const std::string& user, const std::string& pass)
	{
		disconnect();
		SQLFreeHandle(SQL_HANDLE_DBC, conn_);
		SQLAllocHandle(SQL_HANDLE_DBC, env_, &conn_);
		RETCODE rc = SQLConnect(
			conn_
			, (SQLCHAR*)dsn.c_str(), SQL_NTS
			, user.empty() ? (SQLCHAR*)user.c_str() : NULL, SQL_NTS
			, pass.empty() ? (SQLCHAR*)pass.c_str() : NULL, SQL_NTS);
		connected_ = detail::success(rc);
		if (!connected_)
			picoDBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
	}

	//! \brief Create new connection object and immediately connect using the given connection string.
	//! \param connection_string The connection string for establishing a connection.
	//! \throws database_error
	//! \see connected()
	void connect(const std::string& connection_string)
	{
		disconnect();
		SQLFreeHandle(SQL_HANDLE_DBC, conn_);
		SQLAllocHandle(SQL_HANDLE_DBC, env_, &conn_);
		SQLCHAR dsn[1024];
		SQLSMALLINT dsn_size = 0;
		RETCODE rc = SQLDriverConnect(
			conn_
			, 0
			, (SQLCHAR*)connection_string.c_str(), SQL_NTS
			, dsn, sizeof(dsn) / sizeof(dsn[0])
			, &dsn_size
			, SQL_DRIVER_NOPROMPT);
		connected_ = detail::success(rc);
		if (!connected_)
			picoDBC_THROW_DATABASE_ERROR(conn_, SQL_HANDLE_DBC);
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
				picoDBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
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
				picoDBC_THROW_DATABASE_ERROR(conn_.native_dbc_handle(), SQL_HANDLE_DBC);
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
	class param
	{
	private:	
		param(const param& rhs)
		: stmt_(rhs.stmt_)
		, column_(rhs.column_)
		{

		}

		~param()
		{

		}

		param& operator=(param rhs)
		{
			swap(rhs);
			return *this;
		}

		void swap(param& rhs)
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

		param(HSTMT stmt, long column)
		: stmt_(stmt)
		, column_(column)
		{

		}

	private:
		friend class picodbc::statement;
		HSTMT stmt_;
		long column_;
		char value_buffer_[512];
		std::string string_buffer_;
		SQLLEN string_buffer_len_;
	};

	template<>
	inline const std::string& param::set<std::string>(const std::string& str)
	{
		string_buffer_ = str;
		string_buffer_len_ = SQL_NTS;
		RETCODE rc = SQLBindParameter(
			stmt_
			, column_ + 1
			, SQL_PARAM_INPUT
			, detail::sql_type_info<std::string>::ctype
			, detail::sql_type_info<std::string>::sqltype
			, (SQLUINTEGER)string_buffer_.size()
			, 0
			, (SQLPOINTER*)string_buffer_.c_str()
			, (SQLLEN)string_buffer_.size() + 1
			, &string_buffer_len_);
		if (!detail::success(rc))
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return string_buffer_;
	}
}

//! \brief Represents a statement on the database.
//! \note statement is non-copyable.
class statement
{
private:
	typedef std::map<long, detail::param*> params_type;

private:
	template<class T>
	T get_from_cache(long column)
	{
		assert(cache_.count(column));
		return detail::convert<T>(cache_[column]);
	}

	template<class T>
	T get_direct(long column, bool error_on_null)
	{
		T value;
		SQLLEN cb_needed;
		RETCODE rc = SQLGetData(stmt_, column + 1, detail::sql_type_info<T>::sqltype, &value, sizeof(value), &cb_needed);
		if(detail::is_null(cb_needed))
			null_[column] = 1;
		if(detail::is_null(cb_needed) && error_on_null)
			throw null_access_error();
		if (!detail::success(rc))
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return value;
	}

public:
	//! \brief Creates a new un-prepared statement.
	//! \see execute(), execute_direct(), open(), prepare()
	statement()
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
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
		for(params_type::iterator i = params_.begin(), end = params_.end(); i != end; ++i)
			delete i->second;
		params_.clear();
		free_results();
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
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}

	//! \brief Execute the previously prepared query now.
	//! \throws database_error
	void execute()
	{
		if(!open())
			return;
		RETCODE rc = SQLExecute(stmt_);
		if (!detail::success(rc))
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
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
	//! \throws database_error
	template<class T>
	const T& bind(long column, const T& value)
	{
		if(!params_.count(column))
			params_[column] = new class detail::param(stmt_, column);
		return params_[column]->set(value);
	}

	//! \brief Resets all currently bound parameters.
	void reset_parameters()
	{
		if(!open())
			return;
		SQLFreeStmt(stmt_, SQL_RESET_PARAMS);
	}

	//! \brief Gets data from the given column in the selected row of the current result set.
	//! \throws database_error
	template<class T>
	T get(long column);

	//! \brief Returns true if and only if the given column in the selected row of the current results set is NULL.
	//! \throws database_error
	bool is_null(long column);

private:
	statement(const statement&); // not defined
	statement& operator=(const statement&); // not defined

private:
	HSTMT stmt_;
	bool open_;
	long position_;
	mutable long rows_;
	mutable long columns_;
	mutable std::map<long, std::string> cache_;
	mutable std::map<long, bool> null_;
	params_type params_;
};

template<>
inline std::string statement::get_direct<std::string>(long column, bool error_on_null)
{
	SQLLEN cb_needed = 0;
	char small_buff[256];				
	RETCODE rc = SQLGetData(stmt_, column + 1, SQL_C_CHAR, small_buff, sizeof(small_buff), &cb_needed);
	if(detail::is_null(cb_needed))
		null_[column] = 1;
	if(detail::is_null(cb_needed) && error_on_null)
	{
		throw null_access_error();
	}
	else if(!detail::success(rc))
	{
		picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
	}
	else if(detail::success(rc) && cb_needed < sizeof(small_buff))
	{
		return std::string(small_buff);
	}
	else if(cb_needed > 0)
	{
		SQLLEN sz_buff = cb_needed + 1;
		char p_data[sz_buff];
		std::size_t offset = sizeof(small_buff) - 1 ;
		std::memcpy(p_data, small_buff, offset);
		rc = SQLGetData(stmt_, column + 1, SQL_C_CHAR, (SQLCHAR*)(p_data + offset), sz_buff - offset, &cb_needed);
        if (!detail::success(rc))
			picoDBC_THROW_DATABASE_ERROR(stmt_, SQL_HANDLE_STMT);
		return std::string(p_data);
	}
	return std::string();
}

template<class T>
inline T statement::get(long column)
{
	if(null_.count(column))
		throw null_access_error();
	if(cache_.count(column))
		return get_from_cache<T>(column);
	return get_direct<T>(column, true);
}

inline bool statement::is_null(long column)
{
	std::string value = get_direct<std::string>(column, false);
	cache_[column] = value;
	return null_.count(column);
}

#undef picoDBC_THROW_DATABASE_ERROR
#undef picoDBC_STRINGIZE
#undef picoDBC_STRINGIZE_I

} // namespace picodbc

#endif // PICODBC_H
