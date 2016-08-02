#ifndef API_H_
#define API_H_

#include <sql.h>
#include <sqlext.h>
#include "string_buffer.h"
#include "Handles.h"
#include "DiagnosticRecord.h"

namespace api {

    // Low level functions (mirror the C API exactly) -------------------------
    // These function signatures are derived from cpp_odbc (part of turbodbc https://github.com/blue-yonder/turbodbc)
    SQLRETURN allocate_handle(SQLSMALLINT handle_type, SQLHANDLE input_handle, SQLHANDLE * output_handle_ptr)
    {
      return SQLAllocHandle(handle_type, input_handle, output_handle_ptr);
    }

    SQLRETURN free_handle(SQLSMALLINT handle_type, SQLHANDLE handle)
    {
      return SQLFreeHandle(handle_type, handle);
    }

    SQLRETURN get_diagnostic_record(SQLSMALLINT handle_type, SQLHANDLE handle, SQLSMALLINT record_id, SQLCHAR * status_code_ptr, SQLINTEGER * native_error_ptr, SQLCHAR * message_text, SQLSMALLINT buffer_length, SQLSMALLINT * text_length_ptr)
    {
      return SQLGetDiagRec(handle_type, handle, record_id, status_code_ptr, native_error_ptr, message_text, buffer_length, text_length_ptr);
    }

    SQLRETURN set_environment_attribute(SQLHENV environment_handle, SQLINTEGER attribute, SQLPOINTER value_ptr, SQLINTEGER string_length)
    {
      return SQLSetEnvAttr(environment_handle, attribute, value_ptr, string_length);
    }

    SQLRETURN set_connection_attribute(SQLHDBC connection_handle, SQLINTEGER attribute, SQLPOINTER value_ptr, SQLINTEGER string_length)
    {
      return SQLSetConnectAttr(connection_handle, attribute, value_ptr, string_length);
    }

    SQLRETURN establish_connection(SQLHDBC connection_handle, SQLHWND window_handle, SQLCHAR * input_connection_string, SQLSMALLINT input_connection_string_length, SQLCHAR * out_connection_string, SQLSMALLINT output_connection_string_buffer_length, SQLSMALLINT * output_connection_string_length, SQLUSMALLINT driver_completion)
    {
      return SQLDriverConnect(connection_handle, window_handle, input_connection_string, input_connection_string_length, out_connection_string, output_connection_string_buffer_length, output_connection_string_length, driver_completion);
    }

    SQLRETURN disconnect(SQLHDBC connection_handle)
    {
      return SQLDisconnect(connection_handle);
    }

    SQLRETURN end_transaction(SQLSMALLINT handle_type, SQLHANDLE connection_or_environment_handle, SQLSMALLINT completion_type)
    {
      return SQLEndTran(handle_type, connection_or_environment_handle, completion_type);
    }

    SQLRETURN get_connection_info(SQLHDBC connection_handle, SQLUSMALLINT info_type, SQLPOINTER info_value_ptr, SQLSMALLINT buffer_length, SQLSMALLINT * string_length_ptr)
    {
      return SQLGetInfo(connection_handle, info_type, info_value_ptr, buffer_length, string_length_ptr);
    }

    SQLRETURN bind_column(SQLHSTMT statement_handle, SQLUSMALLINT column_id, SQLSMALLINT target_type, SQLPOINTER target_value_ptr, SQLLEN buffer_length, SQLLEN * length_indicator_buffer)
    {
      return SQLBindCol(statement_handle, column_id, target_type, target_value_ptr, buffer_length, length_indicator_buffer);
    }

    SQLRETURN bind_parameter(SQLHSTMT statement_handle, SQLUSMALLINT parameter_id, SQLSMALLINT input_output_type, SQLSMALLINT value_type, SQLSMALLINT parameter_type, SQLULEN column_size, SQLSMALLINT decimal_digits, SQLPOINTER parameter_value_ptr, SQLLEN buffer_length, SQLLEN * length_indicator_buffer)
    {
      return SQLBindParameter(statement_handle, parameter_id, input_output_type, value_type, parameter_type, column_size, decimal_digits, parameter_value_ptr, buffer_length, length_indicator_buffer);
    }

    SQLRETURN column_attribute(SQLHSTMT statement_handle, SQLUSMALLINT column_id, SQLUSMALLINT field_identifier, SQLPOINTER character_attribute_ptr, SQLSMALLINT buffer_length, SQLSMALLINT * string_length_ptr, SQLLEN * numeric_attribute_ptr)
    {
      return SQLColAttribute(statement_handle, column_id, field_identifier, character_attribute_ptr, buffer_length, string_length_ptr, numeric_attribute_ptr);
    }

    SQLRETURN execute_prepared_statement(SQLHSTMT statement_handle)
    {
      return SQLExecute(statement_handle);
    }

    SQLRETURN execute_statement(SQLHSTMT statement_handle, SQLCHAR * sql_text, SQLINTEGER sql_length)
    {
      return SQLExecDirect(statement_handle, sql_text, sql_length);
    }

    SQLRETURN fetch_scroll(SQLHSTMT statement_handle, SQLSMALLINT fetch_orientation, SQLLEN fetch_offset)
    {
      return SQLFetchScroll(statement_handle, fetch_orientation, fetch_offset);
    }

    SQLRETURN free_statement(SQLHSTMT statement_handle, SQLUSMALLINT option)
    {
      return SQLFreeStmt(statement_handle, option);
    }

    SQLRETURN get_statement_attribute(SQLHSTMT statement_handle, SQLINTEGER attribute, SQLPOINTER value_ptr, SQLINTEGER buffer_length, SQLINTEGER * string_length_ptr)
    {
      return SQLGetStmtAttr(statement_handle, attribute, value_ptr, buffer_length, string_length_ptr);
    }

    SQLRETURN number_of_result_columns(SQLHSTMT statement_handle, SQLSMALLINT * destination)
    {
      return SQLNumResultCols(statement_handle, destination);
    }

    SQLRETURN number_of_parameters(SQLHSTMT statement_handle, SQLSMALLINT * destination)
    {
      return SQLNumParams(statement_handle, destination);
    }

    SQLRETURN prepare_statement(SQLHSTMT statement_handle, SQLCHAR * statement_text, SQLINTEGER text_length)
    {
      return SQLPrepare(statement_handle, statement_text, text_length);
    }

    SQLRETURN set_statement_attribute(SQLHSTMT statement_handle, SQLINTEGER attribute, SQLPOINTER value_ptr, SQLINTEGER string_length)
    {
      return SQLSetStmtAttr(statement_handle, attribute, value_ptr, string_length);
    }

    SQLRETURN row_count(SQLHSTMT statement_handle, SQLLEN * count)
    {
      return SQLRowCount(statement_handle, count);
    }

    SQLRETURN describe_column(SQLHSTMT statement_handle, SQLUSMALLINT column_number, SQLCHAR * column_name, SQLSMALLINT buffer_length, SQLSMALLINT * name_length, SQLSMALLINT * data_type, SQLULEN * column_size, SQLSMALLINT * decimal_digits, SQLSMALLINT * nullable)
    {
      return SQLDescribeCol(statement_handle, column_number, column_name, buffer_length, name_length, data_type, column_size, decimal_digits, nullable);
    }

    SQLRETURN describe_parameter(SQLHSTMT statement_handle, SQLUSMALLINT parameter_number, SQLSMALLINT * data_type, SQLULEN * column_size, SQLSMALLINT * decimal_digits, SQLSMALLINT * nullable)
    {
      return SQLDescribeParam(statement_handle, parameter_number, data_type, column_size, decimal_digits, nullable);
    }

    SQLRETURN more_results(SQLHSTMT statement_handle)
    {
      return SQLMoreResults(statement_handle);
    }

    // Higher level functions
    template <typename Output_Handle, typename Input_Handle>
      Output_Handle allocate_handle(Input_Handle const & input_handle) {
        Output_Handle output_handle = {nullptr};
        SQLRETURN return_code = allocate_handle(output_handle.type(), input_handle.handle(), &output_handle.handle());

        if (return_code == SQL_SUCCESS) {
          return output_handle;
        } else {
          throw OdbcError(get_diagnostic_record(input_handle));
        }
      }

    template <typename Handle>
      void free_handle(Handle & handle) {
        SQLRETURN return_code = free_handle(handle.type(), handle.handle);

        if (return_code == SQL_ERROR) {
          throw OdbcError(get_diagnostic_record(handle));
        }
      }

    template <typename Handle>
      void throw_on_error(SQLRETURN return_code, Handle const & handle) {
        if (return_code == SQL_ERROR) {
          throw OdbcError(get_diagnostic_record(handle));
        }
      }

    DiagnosticRecord get_diagnostic_record(signed short int type, void * handle) {
      DiagnosticRecord record;
      fixed_length_string_buffer<5> status_code;
      SQLINTEGER native_error = 0;
      string_buffer message(1024);
      SQLSMALLINT record_id = 1;
      SQLRETURN return_code;

      for(return_code = get_diagnostic_record(type, handle, record_id++, status_code.data_pointer(), &native_error, message.data_pointer(), message.capacity(), message.size_pointer());
          return_code == SQL_SUCCESS;
          return_code = get_diagnostic_record(type, handle, record_id++, status_code.data_pointer(), &native_error, message.data_pointer(), message.capacity(), message.size_pointer()))
      {
        record.push_back(status_code, native_error, message);
      }
      if (return_code == SQL_ERROR) {
        throw OdbcError("Obtaining diagnostic record failed");
      }
      return record;
    }

    StatementHandle allocate_statement_handle(ConnectionHandle const & input_handle) {
      allocate_handle<StatementHandle>(input_handle);
    }

    ConnectionHandle allocate_connection_handle(EnvironmentHandle const & input_handle) {
      allocate_handle<ConnectionHandle>(input_handle);
    }
    void free_handle(StatementHandle & handle) {
      free_handle<StatementHandle>(handle);
    }

    void free_handle(ConnectionHandle & handle) {
      free_handle<ConnectionHandle>(handle);
    }

    DiagnosticRecord get_diagnostic_record(StatementHandle const & handle) {
      get_diagnostic_record(handle.type(), handle.handle());
    }

    DiagnosticRecord get_diagnostic_record(ConnectionHandle const & handle) {
      get_diagnostic_record(handle.type(), handle.handle());
    }

    //void set_environment_attribute(environment_handle const & handle, SQLINTEGER attribute, long value);
    void set_connection_attribute(ConnectionHandle const & handle, SQLINTEGER attribute, long value) {

      // ODBC's interface transfers integer values disguised as a pointer.
      SQLPOINTER const value_ptr = reinterpret_cast<SQLPOINTER>(value);
      SQLRETURN return_code = set_connection_attribute(handle.handle(), attribute, value_ptr, 0);

      throw_on_error(return_code, handle);
    }

    void establish_connection(ConnectionHandle & handle, std::string const & connection_string);
    void disconnect(ConnectionHandle & handle);
    void end_transaction(ConnectionHandle const & handle, SQLSMALLINT completion_type);
    std::string get_string_connection_info(ConnectionHandle const & handle, SQLUSMALLINT info_type);
    SQLUINTEGER get_integer_connection_info(ConnectionHandle const & handle, SQLUSMALLINT info_type);
    void bind_column(StatementHandle const & handle, SQLUSMALLINT column_id, SQLSMALLINT column_type, multi_value_buffer & column_buffer);
    void bind_input_parameter(StatementHandle const & handle, SQLUSMALLINT parameter_id, SQLSMALLINT value_type, SQLSMALLINT parameter_type, multi_value_buffer & parameter_values);
    void execute_prepared_statement(StatementHandle const & handle);
    void execute_statement(StatementHandle const & handle, std::string const & sql);
    bool fetch_scroll(StatementHandle const & StatementHandle, SQLSMALLINT fetch_orientation, SQLLEN fetch_offset);
    void free_statement(StatementHandle const & handle, SQLUSMALLINT option);
    long get_integer_column_attribute(StatementHandle const & handle, SQLUSMALLINT column_id, SQLUSMALLINT field_identifier);
    long get_integer_statement_attribute(StatementHandle const & handle, SQLINTEGER attribute);
    std::string get_string_column_attribute(StatementHandle const & handle, SQLUSMALLINT column_id, SQLUSMALLINT field_identifier);
    short int number_of_result_columns(StatementHandle const & handle);
    short int number_of_parameters(StatementHandle const & handle);
    void prepare_statement(StatementHandle const & handle, std::string const & sql);
    void set_statement_attribute(StatementHandle const & handle, SQLINTEGER attribute, long value);
    void set_statement_attribute(StatementHandle const & handle, SQLINTEGER attribute, SQLULEN * pointer);
    SQLLEN row_count(StatementHandle const & handle);
    column_description describe_column(StatementHandle const & handle, SQLUSMALLINT column_id);
    column_description describe_parameter(StatementHandle const & handle, SQLUSMALLINT parameter_id);
    bool more_results(StatementHandle const & handle);

    //StatementHandle allocate_statement_handle(connection_handle const & input_handle) {
      // Higher level API functions
      //template <typename Handle>
      //void throw_on_error(SQLRETURN return_code, const Handle& handle) {
        //if (return_code == SQL_ERROR) {
          //throw OdbcError(get_diagnostic_record(handle));
        //}
      //}

    void establish_connection(ConnectionHandle& handle, std::string const & connection_string) {
      input_string_buffer input_connection_string(connection_string);
      string_buffer output_connection_string(1024);

      SQLRETURN return_code = establish_connection(
          handle,
          nullptr,
          input_connection_string.data_pointer(),
          input_connection_string.size(),
          output_connection_string.data_pointer(),
          output_connection_string.capacity(),
          output_connection_string.size_pointer(),
          SQL_DRIVER_NOPROMPT);
      throw_on_error(return_code, handle);
    }

    void disconnect(ConnectionHandle& handle) {
      SQLRETURN return_code = disconnect(handle);
      throw_on_error(return_code, handle);
    }
};

#endif // API_H_
