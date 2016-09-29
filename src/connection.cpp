#include "Rcpp.h"
#include "cpp_odbc/connection.h"
#include "cpp_odbc/make_environment.h"
#include "odbconnect_types.h"
#include <sqlext.h>
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

// [[Rcpp::export]]
connection_ptr odbconnect_connect(std::string connection_string) {
  auto environment = cpp_odbc::make_environment();
  return connection_ptr(new std::shared_ptr<turbodbc::connection>(new turbodbc::connection(environment->make_connection(connection_string))));
}

// [[Rcpp::export]]
Rcpp::List connection_info(connection_ptr p) {
    return Rcpp::List::create(
      Rcpp::_["dbname"] = (*p)->get_connection()->get_string_info(SQL_DBMS_NAME),
      Rcpp::_["db.version"]     = (*p)->get_connection()->get_string_info(SQL_DBMS_VER),
      Rcpp::_["username"] = "",
      Rcpp::_["host"] = "",
      Rcpp::_["port"] = "",
      Rcpp::_["sourcename"]   = (*p)->get_connection()->get_string_info(SQL_DATA_SOURCE_NAME),
      Rcpp::_["servername"]   = (*p)->get_connection()->get_string_info(SQL_SERVER_NAME),
      Rcpp::_["drivername"]   = (*p)->get_connection()->get_string_info(SQL_DRIVER_NAME),
      Rcpp::_["odbc.version"]   = (*p)->get_connection()->get_string_info(SQL_ODBC_VER),
      Rcpp::_["driver.version"]   = (*p)->get_connection()->get_string_info(SQL_DRIVER_VER),
      Rcpp::_["odbcdriver.version"]   = (*p)->get_connection()->get_string_info(SQL_DRIVER_ODBC_VER)
    );
}

// [[Rcpp::export]]
void connection_release(connection_ptr p) {
  p.release();
  return;
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
  auto c = turbodbc::cursor(*p, 1024, 0, false);
  return c.sql_tables(catalog_name, schema_name, table_name, table_type);
}

// "%" is a wildcard for all possible values
// [[Rcpp::export]]
Rcpp::RObject connection_sql_columns(connection_ptr p,
    std::string catalog_name = "%",
    std::string schema_name = "%",
    std::string table_name = "%",
    std::string table_type = "%") {
  auto c = turbodbc::cursor(*p, 1024, 0, false);
  return c.sql_columns(catalog_name, schema_name, table_name, table_type);
}
