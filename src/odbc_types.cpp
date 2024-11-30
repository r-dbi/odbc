#include <unordered_map>
#include <string>
#include <sql.h>
#include <sqlext.h>
#include <sqlucode.h>
#include "utils.h"
#define INSTANTIATE_SQL_DATA_TYPE(TYPE) _the_map[#TYPE] = SQL_##TYPE;

using namespace odbc;
const std::unordered_map< std::string, int >& generateOdbcTypes() {
  static std::unordered_map< std::string, int > _the_map;
  INSTANTIATE_SQL_DATA_TYPE(CHAR);
  INSTANTIATE_SQL_DATA_TYPE(VARCHAR)
  INSTANTIATE_SQL_DATA_TYPE(LONGVARCHAR);

  INSTANTIATE_SQL_DATA_TYPE(WCHAR);
  INSTANTIATE_SQL_DATA_TYPE(WVARCHAR);
  INSTANTIATE_SQL_DATA_TYPE(WLONGVARCHAR);

  INSTANTIATE_SQL_DATA_TYPE(DECIMAL);
  INSTANTIATE_SQL_DATA_TYPE(NUMERIC);
  INSTANTIATE_SQL_DATA_TYPE(SMALLINT);
  INSTANTIATE_SQL_DATA_TYPE(INTEGER);
  INSTANTIATE_SQL_DATA_TYPE(REAL);
  INSTANTIATE_SQL_DATA_TYPE(FLOAT);
  INSTANTIATE_SQL_DATA_TYPE(DOUBLE);

  INSTANTIATE_SQL_DATA_TYPE(BIT);
  INSTANTIATE_SQL_DATA_TYPE(TINYINT);
  INSTANTIATE_SQL_DATA_TYPE(BIGINT);

  INSTANTIATE_SQL_DATA_TYPE(BINARY);
  INSTANTIATE_SQL_DATA_TYPE(VARBINARY);
  INSTANTIATE_SQL_DATA_TYPE(LONGVARBINARY);

  INSTANTIATE_SQL_DATA_TYPE(TYPE_DATE);
  INSTANTIATE_SQL_DATA_TYPE(TYPE_TIME);
  INSTANTIATE_SQL_DATA_TYPE(TYPE_TIMESTAMP);
  return _the_map;
}

//' Access the definition of the named SQL Data Type.
//'
//' @description Helper method returning the integer of the
//' [SQL Data Type](https://learn.microsoft.com/en-us/sql/odbc/reference/appendixes/sql-data-types?view=sql-server-ver16)
//' named in the argument.
//'
//' @seealso <https://github.com/microsoft/ODBC-Specification/blob/master/Windows/inc/sql.h>
//' @rdname odbcDataType.
//' @examples
//' \dontrun{
//' library(odbc)
//' ODBC_TYPE("LONGVARCHAR")
//' }
//' @export
// [[Rcpp::export]]
int ODBC_TYPE(const std::string& type) {
  static const std::unordered_map< std::string, int >& map =
    generateOdbcTypes();
  auto itr = map.find(type);
  if (itr != map.end())
  {
    return (int)itr->second;
  }
  utils::raise_error("Could not map input string to ODBC type");
  return 0;
}
