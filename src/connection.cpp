#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include "cpp_odbc/make_environment.h"
#include "odbconnect_types.h"
#include <sqlext.h>
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

// [[Rcpp::export]]
connection_ptr connect(std::string connection_string) {
  boost::shared_ptr<cpp_odbc::environment const> environment = cpp_odbc::make_environment();
  boost::shared_ptr<turbodbc::connection const> p = boost::make_shared<turbodbc::connection const>(environment->make_connection(connection_string));
  return connection_ptr(new boost::shared_ptr<turbodbc::connection const>(p));
}

// [[Rcpp::export]]
std::string connect_info(connection_ptr p) {
  return (*p)->get_connection()->get_string_info(SQL_SERVER_NAME);
}

// [[Rcpp::export]]
Rcpp::RObject get_tables(connection_ptr p) {
  auto c = boost::make_shared<turbodbc::cursor>(turbodbc::cursor((*p), 1024, 0, false));
  return c->get_tables()->fetch_all();
}

// [[Rcpp::export]]
void connection_release(connection_ptr p) {
  return p.release();
}

// [[Rcpp::export]]
bool connection_valid(connection_ptr p) {
  return p.get() != NULL;
}
