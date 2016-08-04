#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include "cpp_odbc/make_environment.h"
#include "odbconnect_types.h"
#include <sqlext.h>
#include <boost/shared_ptr.hpp>
#include "turbodbc/cursor.h"
#include "turbodbc/result_sets/r_result_set.h"

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
Rcpp::RObject query(connection_ptr p, std::string sql) {

  auto c = turbodbc::cursor((*p), 1000, 1000, false);
  c.prepare(sql);
  c.execute();
  auto r = turbodbc::result_sets::r_result_set(*c.get_result_set());
  return r.fetch_row();
}
