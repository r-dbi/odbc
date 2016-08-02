#include "Handles.h"
#include "api.h"

ConnectionHandle::ConnectionHandle(const Handle& input_handle) {
  SQLRETURN return_code = api::allocate_handle(SQL_HANDLE_DBC, input_handle.handle(), &handle_);
  if (return_code != SQL_SUCCESS) {
    throw OdbcError(api::get_diagnostic_record(input_handle));
  }
}

~ConnectionHandle::ConnectionHandle() {
  SQLRETURN return_code = api::free_handle(SQL_HANDLE_DBC, handle_);
  if (return_code == SQL_ERROR) {
    throw OdbcError(api::get_diagnostic_record(handle_));
  }
}

signed short ConnectionHandle::type() {
  return SQL_HANDLE_DBC;
}

signed short StatementHandle::type() {
  return SQL_HANDLE_STMT;
}
