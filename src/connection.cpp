#include "ODBCConnection.h"

// [[Rcpp::export]]
XPtr<ODBCConnectionPtr> connection_create(std::string x) {
  ODBCConnectionPtr* p = new ODBCConnectionPtr(new ODBCConnection(x));
  return XPtr<ODBCConnectionPtr>(p, true);
}
