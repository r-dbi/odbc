#include "Handles.h"
#include "ODBCConnection.h"

// [[Rcpp::export]]
XPtr<ConnectionPtr> connection_create(std::string x) {
  ConnectionPtr* p = new ConnectionPtr(new ConnectionHandle(x));
  return XPtr<ConnectionPtr>(p, true);
}

// [[Rcpp::export]]
std::string format_connection(XPtr<ConnectionPtr> c) {
  return (*c)->format();
}
