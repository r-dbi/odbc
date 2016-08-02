#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include "cpp_odbc/make_environment.h"
#include "odbconnect_types.h"

// [[Rcpp::export]]
connection_ptr connect(std::string connection_string) {
  auto environment = cpp_odbc::make_environment();
  auto p = environment->make_connection(connection_string);
  return connection_ptr(&p);
}
