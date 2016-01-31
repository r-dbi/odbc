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

#define NANODBC_COLUMN(p) \
    std::cout << std::setw(25) << std::left << #p << ": " << std::right << any_to_string(cols.p()) << std::endl

#define ODBC_CHECK(r, handle, handle_type, msg) \
    if (r!=SQL_SUCCESS && r != SQL_SUCCESS_WITH_INFO) \
        throw nanodbc::database_error(handle, handle_type, msg)

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
            NANODBC_COLUMN(data_type);
            NANODBC_COLUMN(sql_data_type);
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
