#include "Rcpp.h"
#include "condition.h"
#include "nanodbc.h"
#include "odbc_types.h"
#include "r_types.h"

using namespace odbc;

// [[Rcpp::export]]
Rcpp::DataFrame list_drivers_() {
  std::vector<std::string> names;
  std::vector<std::string> attributes;
  std::vector<std::string> values;
  for (auto& driver : nanodbc::list_drivers()) {
    if (driver.attributes.size() == 0) {
      names.push_back(driver.name);
      attributes.push_back("");
      values.push_back("");
    } else {
      for (auto& attr : driver.attributes) {
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
  for (auto& data_source : nanodbc::list_data_sources()) {
    names.push_back(data_source.name);
    descriptions.push_back(data_source.description);
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = names,
      Rcpp::_["description"] = descriptions,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
connection_ptr odbc_connect(
    std::string const& connection_string,
    std::string const& timezone = "",
    std::string const& timezone_out = "",
    std::string const& encoding = "",
    std::string const& name_encoding = "",
    int bigint = 0,
    long timeout = 0,
    Rcpp::Nullable<Rcpp::List> const& r_attributes = R_NilValue,
    bool const& interruptible_execution = true) {
  return connection_ptr(
      new std::shared_ptr<odbc_connection>(new odbc_connection(
          connection_string,
          timezone,
          timezone_out,
          encoding,
          name_encoding,
          static_cast<bigint_map_t>(bigint),
          timeout,
          r_attributes,
          interruptible_execution)));
}

std::string get_info_or_empty(connection_ptr const& p, short type) {
  try {
    return (*p)->connection()->get_info<std::string>(type);
  } catch (const nanodbc::database_error& c) {
    return "";
  }
}

// [[Rcpp::export]]
bool has_result(connection_ptr const& p) {
  return (*p)->has_result();
}

// [[Rcpp::export]]
Rcpp::List connection_info(connection_ptr const& p) {
  std::uint64_t getdata_ext;
  std::uint64_t owner_usage;
  try {
    getdata_ext =
        (*p)->connection()->get_info<std::uint64_t>(SQL_GETDATA_EXTENSIONS);
    owner_usage =
        (*p)->connection()->get_info<std::uint64_t>(SQL_SCHEMA_USAGE);
  } catch (const nanodbc::database_error& c) {
    getdata_ext = 0;
    owner_usage = 0;
  }

  return Rcpp::List::create(
      Rcpp::_["dbname"] = get_info_or_empty(p, SQL_DATABASE_NAME),
      Rcpp::_["dbms.name"] = get_info_or_empty(p, SQL_DBMS_NAME),
      Rcpp::_["db.version"] = get_info_or_empty(p, SQL_DBMS_VER),
      Rcpp::_["username"] = get_info_or_empty(p, SQL_USER_NAME),
      Rcpp::_["host"] = "",
      Rcpp::_["port"] = "",
      Rcpp::_["sourcename"] = get_info_or_empty(p, SQL_DATA_SOURCE_NAME),
      Rcpp::_["servername"] = get_info_or_empty(p, SQL_SERVER_NAME),
      Rcpp::_["drivername"] = get_info_or_empty(p, SQL_DRIVER_NAME),
      Rcpp::_["odbc.version"] = get_info_or_empty(p, SQL_ODBC_VER),
      Rcpp::_["driver.version"] = get_info_or_empty(p, SQL_DRIVER_VER),
      Rcpp::_["odbcdriver.version"] = get_info_or_empty(p, SQL_DRIVER_ODBC_VER),
      Rcpp::_["supports.transactions"] = (*p)->supports_transactions(),
      Rcpp::_["supports.catalogs"] = get_info_or_empty(p, SQL_CATALOG_NAME) == "Y" ? true : false,
      Rcpp::_["supports.schema"] = owner_usage == 0 ? false : true,
      Rcpp::_["getdata.extensions.any_column"] =
          ((getdata_ext & SQL_GD_ANY_COLUMN) != 0),
      Rcpp::_["getdata.extensions.any_order"] =
          ((getdata_ext & SQL_GD_ANY_ORDER) != 0));
}

// [[Rcpp::export]]
std::string connection_quote(connection_ptr const& p) {
  return get_info_or_empty(p, SQL_IDENTIFIER_QUOTE_CHAR);
}

// [[Rcpp::export]]
void connection_release(connection_ptr p) {
  if (p.get() != nullptr && (*p)->has_active_result()) {
    Rcpp::warning(
        "%s\n%s",
        "There is a result object still in use.",
        "The connection will be automatically released when it is closed");
  }
  p.release();
}

// [[Rcpp::export]]
void connection_begin(connection_ptr const& p) { (*p)->begin(); }

// [[Rcpp::export]]
void connection_commit(connection_ptr const& p) { (*p)->commit(); }

// [[Rcpp::export]]
void connection_rollback(connection_ptr const& p) { (*p)->rollback(); }

// [[Rcpp::export]]
bool connection_valid(connection_ptr const& p) { return p.get() != nullptr; }

// [[Rcpp::export]]
Rcpp::DataFrame connection_sql_tables(
    connection_ptr const& p,
    SEXP catalog_name = R_NilValue,
    SEXP schema_name = R_NilValue,
    SEXP table_name = R_NilValue,
    SEXP table_type = R_NilValue) {
  auto c = nanodbc::catalog(*(*p)->connection());
  nanodbc::catalog::tables tables = nanodbc::catalog::tables(c.find_tables(
      table_name == R_NilValue ? nullptr : Rcpp::as<const char*>(table_name),
      table_type == R_NilValue ? nullptr : Rcpp::as<const char*>(table_type),
      schema_name == R_NilValue ? nullptr : Rcpp::as<const char*>(schema_name),
      catalog_name == R_NilValue ? nullptr
                                 : Rcpp::as<const char*>(catalog_name)));
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
      Rcpp::_["table_schema"] = schemas,
      Rcpp::_["table_name"] = names,
      Rcpp::_["table_type"] = types,
      Rcpp::_["table_remarks"] = remarks,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
Rcpp::StringVector connection_sql_catalogs(
    connection_ptr const& p ) {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto res = c.list_catalogs();
  Rcpp::StringVector ret;
  for ( const auto& val : res )
  {
    ret.push_back( val );
  }

  return ret;
}

// [[Rcpp::export]]
Rcpp::StringVector connection_sql_schemas(
    connection_ptr const& p ) {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto res = c.list_schemas();
  Rcpp::StringVector ret;
  for ( const auto& val : res )
  {
    ret.push_back( val );
  }

  return ret;
}

// [[Rcpp::export]]
Rcpp::StringVector connection_sql_table_types(
    connection_ptr const& p ) {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto res = c.list_table_types();
  Rcpp::StringVector ret;
  for ( const auto& val : res )
  {
    ret.push_back( val );
  }

  return ret;
}

// "%" is a wildcard for all possible values
// [[Rcpp::export]]
Rcpp::DataFrame connection_sql_columns(
    connection_ptr const& p,
    SEXP column_name = R_NilValue,
    SEXP catalog_name = R_NilValue,
    SEXP schema_name = R_NilValue,
    SEXP table_name = R_NilValue) {
  auto c = nanodbc::catalog(*(*p)->connection());
  auto tables = c.find_columns(
      column_name == R_NilValue ? nullptr : Rcpp::as<const char*>(column_name),
      table_name == R_NilValue ? nullptr : Rcpp::as<const char*>(table_name),
      schema_name == R_NilValue ? nullptr : Rcpp::as<const char*>(schema_name),
      catalog_name == R_NilValue ? nullptr
                                 : Rcpp::as<const char*>(catalog_name));

  std::vector<std::string> column_names;
  std::vector<std::string> table_names;
  std::vector<std::string> schema_names;
  std::vector<std::string> catalog_names;
  std::vector<short> data_type;
  std::vector<std::string> type_name;
  std::vector<long> column_size;
  std::vector<long> buffer_length;
  std::vector<short> decimal_digits;
  std::vector<short> numeric_precision_radix;
  std::vector<bool> nullable;
  std::vector<std::string> remarks;
  std::vector<std::string> column_default;
  std::vector<short> sql_data_type;
  std::vector<short> sql_datetime_subtype;
  std::vector<long> char_octet_length;
  std::vector<long> ordinal_position;

  while (tables.next()) {
    column_names.push_back(tables.column_name());
    table_names.push_back(tables.table_name());
    schema_names.push_back(tables.table_schema());
    catalog_names.push_back(tables.table_catalog());
    data_type.push_back(tables.data_type());
    type_name.push_back(tables.type_name());
    column_size.push_back(tables.column_size());
    buffer_length.push_back(tables.buffer_length());
    decimal_digits.push_back(tables.decimal_digits());
    numeric_precision_radix.push_back(tables.numeric_precision_radix());
    nullable.push_back(tables.nullable());
    remarks.push_back(tables.remarks());
    column_default.push_back(tables.column_default());
    sql_data_type.push_back(tables.sql_data_type());
    sql_datetime_subtype.push_back(tables.sql_datetime_subtype());
    char_octet_length.push_back(tables.char_octet_length());
    ordinal_position.push_back(tables.ordinal_position());
  }
  return Rcpp::DataFrame::create(
      Rcpp::_["name"] = column_names,
      Rcpp::_["field.type"] = type_name,
      Rcpp::_["table_name"] = table_names,
      Rcpp::_["schema_name"] = schema_names,
      Rcpp::_["catalog_name"] = catalog_names,
      Rcpp::_["data_type"] = data_type,
      Rcpp::_["column_size"] = column_size,
      Rcpp::_["buffer_length"] = buffer_length,
      Rcpp::_["decimal_digits"] = decimal_digits,
      Rcpp::_["numeric_precision_radix"] = numeric_precision_radix,
      Rcpp::_["remarks"] = remarks,
      Rcpp::_["column_default"] = column_default,
      Rcpp::_["sql_data_type"] = sql_data_type,
      Rcpp::_["sql_datetime_subtype"] = sql_datetime_subtype,
      Rcpp::_["char_octet_length"] = char_octet_length,
      Rcpp::_["ordinal_position"] = ordinal_position,
      Rcpp::_["nullable"] = nullable,
      Rcpp::_["stringsAsFactors"] = false);
}

// [[Rcpp::export]]
Rcpp::IntegerVector transactionLevels() {
  Rcpp::IntegerVector out = Rcpp::IntegerVector::create(
      Rcpp::_["read_uncommitted"] = SQL_TXN_READ_UNCOMMITTED,
      Rcpp::_["read_committed"] = SQL_TXN_READ_COMMITTED,
      Rcpp::_["repeatable_read"] = SQL_TXN_REPEATABLE_READ,
      Rcpp::_["serializable"] = SQL_TXN_SERIALIZABLE);
  return out;
}

// [[Rcpp::export]]
void set_transaction_isolation(connection_ptr const& p, size_t level) {
  auto c = (*p)->connection();
  SQLSetConnectAttr(
      c->native_dbc_handle(), SQL_ATTR_TXN_ISOLATION, (SQLPOINTER)level, 0);
}

// [[Rcpp::export]]
Rcpp::IntegerVector bigint_mappings() {
  Rcpp::IntegerVector out = Rcpp::IntegerVector::create(
      Rcpp::_["integer64"] = bigint_map_t::i64_to_integer64,
      Rcpp::_["integer"] = bigint_map_t::i64_to_integer,
      Rcpp::_["numeric"] = bigint_map_t::i64_to_double,
      Rcpp::_["character"] = bigint_map_t::i64_to_character);
  return out;
}
