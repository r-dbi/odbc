#include "Rcpp.h"
#include "nanodbc.h"
#include "odbc_types.h"
#include <sqlext.h>
#include "condition.h"

using namespace odbc;

// [[Rcpp::export]]
Rcpp::DataFrame list_drivers_() {
  std::vector<std::string> names;
  std::vector<std::string> attributes;
  std::vector<std::string> values;
  for (auto &driver : nanodbc::list_drivers()) {
    if (driver.attributes.size() == 0) {
      names.push_back(driver.name);
      attributes.push_back("");
      values.push_back("");
    } else {
      for (auto &attr : driver.attributes) {
        names.push_back(driver.name);
        attributes.push_back(attr.keyword);
        values.push_back(attr.value);
      }
    }
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names,
      Rcpp::_["attribute"] = attributes,
      Rcpp::_["value"] = values,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
Rcpp::DataFrame list_data_sources_() {
  std::vector<std::string> names;
  std::vector<std::string> descriptions;
  for (auto &data_source : nanodbc::list_data_sources()) {
    names.push_back(data_source.name);
    descriptions.push_back(data_source.description);
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names,
      Rcpp::_["description"] = descriptions,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
connection_ptr odbc_connect(std::string const &connection_string, std::string const &timezone = "") {
  return connection_ptr(new std::shared_ptr<odbc_connection>(
      new odbc_connection(connection_string, timezone)));
}

std::string get_info_or_empty(connection_ptr const &p, short type) {
  try {
    return (*p)->connection()->get_info<std::string>(type);
  } catch(nanodbc::database_error c) {
    return "";
  }
}

// [[Rcpp::export]]
Rcpp::List connection_info(connection_ptr const &p) {
  return Rcpp::List::create(
      Rcpp::_["dbname"] = get_info_or_empty(p, SQL_DATABASE_NAME),
      Rcpp::_["dbms.name"] = get_info_or_empty(p, SQL_DBMS_NAME),
      Rcpp::_["db.version"] = get_info_or_empty(p, SQL_DBMS_VER),
      Rcpp::_["username"] = get_info_or_empty(p, SQL_USER_NAME),
      Rcpp::_["host"] = "", Rcpp::_["port"] = "",
      Rcpp::_["sourcename"] = get_info_or_empty(p, SQL_DATA_SOURCE_NAME),
      Rcpp::_["servername"] = get_info_or_empty(p, SQL_SERVER_NAME),
      Rcpp::_["drivername"] = get_info_or_empty(p, SQL_DRIVER_NAME),
      Rcpp::_["odbc.version"] = get_info_or_empty(p, SQL_ODBC_VER),
      Rcpp::_["driver.version"] = get_info_or_empty(p, SQL_DRIVER_VER),
      Rcpp::_["odbcdriver.version"] = get_info_or_empty(p, SQL_DRIVER_ODBC_VER),
      Rcpp::_["supports.transactions"] = (*p)->supports_transactions());
}

// [[Rcpp::export]]
std::string connection_quote(connection_ptr const &p) {
  return get_info_or_empty(p, SQL_IDENTIFIER_QUOTE_CHAR);
}

// [[Rcpp::export]]
void connection_release(connection_ptr p) {
  if (p.get() != nullptr && (*p)->has_active_result()) {
    Rcpp::warning(
        "%s\n%s", "There is a result object still in use.",
        "The connection will be automatically released when it is closed");
  }
  p.release();
}

// [[Rcpp::export]]
void connection_begin(connection_ptr const &p) { (*p)->begin(); }

// [[Rcpp::export]]
void connection_commit(connection_ptr const &p) { (*p)->commit(); }

// [[Rcpp::export]]
void connection_rollback(connection_ptr const &p) { (*p)->rollback(); }

// [[Rcpp::export]]
bool connection_valid(connection_ptr const &p) { return p.get() != nullptr; }

// [[Rcpp::export]]
Rcpp::DataFrame connection_sql_tables(
    connection_ptr const &p, std::string const &catalog_name = "",
    std::string const &schema_name = "", std::string const &table_name = "",
    std::string const &table_type = "") {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto tables =
      c.find_tables(table_name, table_type, schema_name, catalog_name);
  std::vector<std::string> names;
  std::vector<std::string> types;
  std::vector<std::string> schemas;
  std::vector<std::string> remarks;
  std::vector<std::string> catalog;

  while (tables.next()) {
    names.push_back(tables.table_name());
    types.push_back(tables.table_type());
    schemas.push_back(tables.table_schema());
    remarks.push_back(tables.table_remarks());
    catalog.push_back(tables.table_catalog());
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["table_catalog"] = catalog,
      Rcpp::_["table_name"] = names,
      Rcpp::_["table_type"] = types,
      Rcpp::_["table_schema"] = schemas,
      Rcpp::_["table_remarks"] = remarks,
      Rcpp::_["stringsAsFactors"] = false);
}

// "%" is a wildcard for all possible values
// [[Rcpp::export]]
Rcpp::DataFrame connection_sql_columns(connection_ptr const &p,
                                       std::string const &column_name = "",
                                       std::string const &catalog_name = "",
                                       std::string const &schema_name = "",
                                       std::string const &table_name = "") {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto tables =
      c.find_columns(column_name, table_name, schema_name, catalog_name);
  std::vector<std::string> names;
  std::vector<std::string> field_type;
  // std::vector<std::string> data_type; // TODO expose sql type to r type
  // mapping
  std::vector<bool> nullable;
  while (tables.next()) {
    names.push_back(tables.column_name());
    field_type.push_back(tables.type_name());
    // data_type.push_back(tables.data_type());
    nullable.push_back(static_cast<bool>(tables.nullable()));
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names, Rcpp::_["field.type"] = field_type,
      Rcpp::_["nullable"] = nullable, Rcpp::_["stringsAsFactors"] = false);
}
