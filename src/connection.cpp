#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include "cpp_odbc/make_environment.h"
#include "odbconnect_types.h"
#include <sqlext.h>
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

// [[Rcpp::export]]
connection_ptr connect(std::string connection_string) {
  auto environment = cpp_odbc::make_environment();
  auto p = boost::make_shared<turbodbc::connection>(environment->make_connection(connection_string));
  return connection_ptr(new boost::shared_ptr<turbodbc::connection const>(p));
}

// [[Rcpp::export]]
std::string connect_info(connection_ptr p) {
  return (*p)->get_connection()->get_string_info(SQL_SERVER_NAME);
}

// [[Rcpp::export]]
void connection_release(connection_ptr p) {
  return p.release();
}

// [[Rcpp::export]]
bool connection_valid(connection_ptr p) {
  return p.get() != NULL;
}

// "%" is a wildcard for all possible values
// [[Rcpp::export]]
Rcpp::RObject connection_sql_tables(connection_ptr p,
    std::string catalog_name = "%",
    std::string schema_name = "%",
    std::string table_name = "%",
    std::string table_type = "%") {
  auto c = boost::make_shared<turbodbc::cursor>(turbodbc::cursor((*p), 1024, 0, false));
  return c->sql_tables(catalog_name, schema_name, table_name, table_type);
}

// "%" is a wildcard for all possible values
// [[Rcpp::export]]
Rcpp::RObject connection_sql_columns(connection_ptr p,
    std::string catalog_name = "%",
    std::string schema_name = "%",
    std::string table_name = "%",
    std::string table_type = "%") {
  auto c = boost::make_shared<turbodbc::cursor>(turbodbc::cursor((*p), 1024, 0, false));
  return c->sql_columns(catalog_name, schema_name, table_name, table_type);
}
