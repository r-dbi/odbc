#include "Rcpp.h"
#include "cpp_odbc/make_environment.h"

Rcpp::XPtr<connection> connect(const std::string& connection_string) {
  auto environment = cpp_odbc::make_environment();
  return Rcpp::XPtr<std::shared_ptr<connection const>>(environment->make_connection(connection_string));
}
