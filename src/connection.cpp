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
  boost::shared_ptr<cpp_odbc::connection const> p = environment->make_connection(connection_string);
  return connection_ptr(new boost::shared_ptr<cpp_odbc::connection const>(p));
}

// [[Rcpp::export]]
std::string connect_info(connection_ptr p) {
  return (*p)->get_string_info(SQL_SERVER_NAME);
}

// [[Rcpp::export]]
cursor_ptr query(connection_ptr p, std::string sql) {

  auto c = boost::make_shared<turbodbc::cursor>(turbodbc::cursor((*p), 1000, 1000, false));
  c->prepare(sql);
  c->execute();

  return cursor_ptr(new boost::shared_ptr<turbodbc::cursor const>(c));
}

// [[Rcpp::export]]
Rcpp::RObject fetch_row(cursor_ptr c) {
  return (*c)->get_result_set()->fetch_all();
}
