#include "api.h"
#include "diagnostic_message.h"
#include "string_buffer.h"

template <typename OutputHandle, typename InputHandle>
OutputHandle allocate_handle(const api& api, const InputHandle & input_handle) {
  OutputHandle output_handle;
  SQLRETURN return_code = api.allocate_handle(output_handle.type(), input_handle.handle(), &output_handle.handle());
  if (return_code == SQL_SUCCESS) {
    return output_handle;
  } else {
    throw OdbcError(get_diagnostic_record(input_handle));
  }
}

template <typename Handle>
void free_handle(const api& api, Handle& handle) {
  SQLRETURN return_code = free_handle(handle.type(), handle.handle());

  if (return_code == SQL_ERROR) {
    throw OdbcError(get_diagnostic_record(handle));
  }
}

template <typename Handle>
void throw_on_error(SQLRETURN return_code, const Handle& handle) {
  if (return_code == SQL_ERROR) {
    throw OdbcError(get_diagnostic_record(handle));
  }
}

class Handle {
  protected:

  public:

  void * handle() const {
    return handle_;
  }

  bool operator==(const Handle& other) const {
    return handle_ == other.handle_;
  }

  bool operator!=(const Handle& other) const {
    return handle_ != other.handle_;
  }

  virtual signed short int type() const = 0;

  DiagnosticRecord get_diagnostic_record(void * handle) {
    DiagnosticRecord records;
    fixed_length_string_buffer<5> status_code;
    SQLINTEGER native_error = 0;
    string_buffer message(1024);
    SQLSMALLINT record_id = 1;
    SQLRETURN return_code;

    for(return_code = api_.get_diagnostic_record(type, handle, record_id++, status_code.data_pointer(), &native_error, message.data_pointer(), message.capacity(), message.size_pointer());
        return_code == SQL_SUCCESS;
        return_code = api_.get_diagnostic_record(type, handle, record_id++, status_code.data_pointer(), &native_error, message.data_pointer(), message.capacity(), message.size_pointer()))
    {
      records.push_back(status_code, native_error, message);
    }
    if (return_code == SQL_ERROR) {
      throw OdbcError("Obtaining diagnostic record failed");
    }
    return records;
  }

  protected:
    api api_;
    void * handle_;
};

class ConnectionHandle : Handle {
  public:
    ConnectionHandle(const Handle& input_handle) {
      SQLRETURN return_code = api_.allocate_handle(SQL_HANDLE_DBC, input_handle.handle(), &handle_);
      if (return_code != SQL_SUCCESS) {
        throw OdbcError(get_diagnostic_record(input_handle.handle()));
      }
    }

    ~ConnectionHandle() {
      SQLRETURN return_code = api_.free_handle(SQL_HANDLE_DBC, handle_);
      if (return_code == SQL_ERROR) {
        throw OdbcError(get_diagnostic_record(handle()));
      }
    }

    signed short type() const {
       return SQL_HANDLE_DBC;
    }
};

class StatementHandle : Handle {
  public:
    StatementHandle(const Handle& input_handle) {
      SQLRETURN return_code = api_.allocate_handle(SQL_HANDLE_STMT, input_handle.handle(), &handle_);
      if (return_code != SQL_SUCCESS) {
        throw OdbcError(get_diagnostic_record(input_handle.handle()));
      }
    }

    ~StatementHandle() {
      SQLRETURN return_code = api_.free_handle(SQL_HANDLE_STMT, handle_);
      if (return_code == SQL_ERROR) {
        throw OdbcError(get_diagnostic_record(handle()));
      }
    }

    signed short type() const {
       return SQL_HANDLE_STMT;
    }
};
