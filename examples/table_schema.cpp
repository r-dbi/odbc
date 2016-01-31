#include "nanodbc.h"
#include "example_unicode_utils.h"

#include <algorithm>
#include <array>
#include <codecvt>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

#ifdef _WIN32
#define NOMINMAX
#include <windows.h> // SQLLEN, SQLULEN, SQLHWND
#endif
#include <sql.h>
#include <sqlext.h>
#include "nanodbc.h"
using namespace std;
using namespace nanodbc;

#define NANODBC_COLUMN(method) \
    std::cout << std::setw(25) << std::left << #method << ": " << std::right << any_to_string(cols.method()) << std::endl

#define NANODBC_COLUMN_EX(method, expr) \
    std::cout << std::setw(25) << std::left << #method << ": " << std::right << (expr) << std::endl

#define ODBC_CHECK(r, handle, handle_type, msg) \
    if (r!=SQL_SUCCESS && r != SQL_SUCCESS_WITH_INFO) \
        throw nanodbc::database_error(handle, handle_type, msg)

inline std::string data_type_identifier(int t)
{
    // List based on https://msdn.microsoft.com/en-us/library/ms710150.aspx
    switch (t)
    {
    case SQL_UNKNOWN_TYPE:  return "SQL_UNKNOWN_TYPE";
    case SQL_CHAR:          return "SQL_CHAR";
    case SQL_VARCHAR:       return "SQL_VARCHAR";
    case SQL_LONGVARCHAR:   return "SQL_LONGVARCHAR";
    case SQL_WCHAR:         return "SQL_WCHAR";
    case SQL_WVARCHAR:      return "SQL_WVARCHAR";
    case SQL_WLONGVARCHAR:  return "SQL_WLONGVARCHAR";
    case SQL_BINARY:        return "SQL_BINARY";
    case SQL_VARBINARY:     return "SQL_VARBINARY";
    case SQL_LONGVARBINARY: return "SQL_LONGVARBINARY";
    case SQL_DECIMAL:       return "SQL_DECIMAL";
    case SQL_NUMERIC:       return "SQL_NUMERIC";
    case SQL_TINYINT:       return "SQL_TINYINT";
    case SQL_SMALLINT:      return "SQL_SMALLINT";
    case SQL_INTEGER:       return "SQL_INTEGER";
    case SQL_BIGINT:        return "SQL_BIGINT";
    case SQL_FLOAT:         return "SQL_FLOAT";
    case SQL_REAL:          return "SQL_REAL";
    case SQL_DOUBLE:        return "SQL_DOUBLE";
    case SQL_BIT:           return "SQL_BIT";
    case SQL_DATETIME:      return "SQL_DATETIME";
    case SQL_TYPE_DATE:     return "SQL_TYPE_DATE";
    case SQL_TYPE_TIME:     return "SQL_TYPE_TIME";
    case SQL_TYPE_TIMESTAMP:return "SQL_TYPE_TIMESTAMP";
    //case SQL_TYPE_UTCDATETIME: return "SQL_TYPE_UTCDATETIME";
    //case SQL_TYPE_UTCTIME:  return "SQL_TYPE_UTCTIME";
    case SQL_INTERVAL_MONTH:return "SQL_INTERVAL_MONTH";
    case SQL_INTERVAL_YEAR: return "SQL_INTERVAL_YEAR";
    case SQL_INTERVAL_YEAR_TO_MONTH: return "SQL_INTERVAL_YEAR_TO_MONTH";
    case SQL_INTERVAL_DAY:  return "SQL_INTERVAL_DAY";
    case SQL_INTERVAL_HOUR: return "SQL_INTERVAL_HOUR";
    case SQL_INTERVAL_MINUTE: return "SQL_INTERVAL_MINUTE";
    case SQL_INTERVAL_SECOND: return "SQL_INTERVAL_SECOND";
    case SQL_INTERVAL_DAY_TO_HOUR: return "SQL_INTERVAL_DAY_TO_HOUR";
    case SQL_INTERVAL_DAY_TO_MINUTE: return "SQL_INTERVAL_DAY_TO_MINUTE";
    case SQL_INTERVAL_DAY_TO_SECOND: return "SQL_INTERVAL_DAY_TO_SECOND";
    case SQL_INTERVAL_HOUR_TO_MINUTE: return "SQL_INTERVAL_HOUR_TO_MINUTE";
    case SQL_INTERVAL_HOUR_TO_SECOND: return "SQL_INTERVAL_HOUR_TO_SECOND";
    case SQL_INTERVAL_MINUTE_TO_SECOND: return "SQL_INTERVAL_MINUTE_TO_SECOND";
    case SQL_GUID:          return "SQL_GUID";
    default:                return std::to_string(t);
    }
}

void usage(std::ostream& out, std::string const& binary_name)
{
    out << "usage: " << binary_name << " connection_string table_name [schema_name]" << std::endl;
}

int main(int argc, char* argv[])
{
    if(argc < 3 || argc > 4)
    {
        char* app_name = strrchr(argv[0], '/');
        app_name = app_name ? app_name + 1 : argv[0];
        if(0 == strncmp(app_name, "lt-", 3))
            app_name += 3; // remove libtool prefix
        usage(cerr, app_name);
        return EXIT_FAILURE;
    }

    try
    {
        // Example:
        // "Driver={ODBC Driver 11 for SQL Server};Server=xxx.sqlserver.net;Database=mydb;UID=joe;PWD=secret;"
        auto const connection_string(convert(argv[1]));
        auto const table_name(convert(argv[2]));
        nanodbc::string_type schema_name;
        if (argc == 4)
            schema_name = convert(argv[3]);

        connection conn(connection_string);
        catalog cat(conn);
        auto cols = cat.find_columns(nanodbc::string_type(), table_name, schema_name);
        while (cols.next())
        {
            if (cols.ordinal_position() == 1)
            {
                NANODBC_COLUMN(table_catalog);
                NANODBC_COLUMN(table_schema);
                NANODBC_COLUMN(table_name);
            }
            std::cout << "--------------------------------" << std::endl;
            NANODBC_COLUMN(ordinal_position);
            NANODBC_COLUMN(column_name);
            NANODBC_COLUMN(type_name);
            NANODBC_COLUMN_EX(data_type, data_type_identifier(cols.data_type()));
            NANODBC_COLUMN_EX(sql_data_type, data_type_identifier(cols.sql_data_type()));
            NANODBC_COLUMN(sql_datetime_subtype);
            NANODBC_COLUMN(column_size);
            NANODBC_COLUMN(decimal_digits);
            NANODBC_COLUMN(buffer_length);
            NANODBC_COLUMN(char_octed_length);
            NANODBC_COLUMN(numeric_precision_radix);
            NANODBC_COLUMN(nullable);
            NANODBC_COLUMN(is_nullable);
            NANODBC_COLUMN(remarks);
            NANODBC_COLUMN(column_default);
            std::cout << std::endl;
        }
    }
    catch (std::runtime_error const& e)
    {
        std::cerr << e.what() << std::endl;
    }
}
