#include "nanodbc.h"
#include "example_unicode_utils.h"

#include <algorithm>
#include <array>
#include <codecvt>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;
using namespace nanodbc;

void usage(ostream& out, string const& binary_name)
{
    out << "usage: " << binary_name << " connection_string" << endl;
}

int main(int argc, char* argv[])
{
    if(argc != 2)
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
        connection conn(connection_string);

        // Create table
        {
            try
            {
                // XXX: SQL Server <=2014 does not support "if exists"
                execute(conn, NANODBC_TEXT("drop table rowset_iteration;"));
            } catch (runtime_error const&) {}

            execute(conn, NANODBC_TEXT("create table rowset_iteration (i int);"));
        }

        // Insert data
        {
            statement stmt(conn);
            prepare(stmt, NANODBC_TEXT("insert into rowset_iteration (i) values (?);"));
            array<int, 5> const numbers {{ 100, 80, 60, 40, 20 }};
            stmt.bind(0, numbers.data(), numbers.size());
            transact(stmt, static_cast<long>(numbers.size()));
        }

        // Select and fetch
        long batch_size = 1; // tweak to play with number of ODBC fetch calls
        result result = execute(
            conn
            , NANODBC_TEXT("SELECT i FROM rowset_iteration ORDER BY i DESC;")
            , batch_size);
        for (int i = 1; result.next(); ++i)
        {
            cout << i
                << "(" << result.rows()
                << "/" << result.rowset_size()
                << ":"
                << result.get<int>(0)
                << endl;
        }
    }
    catch (runtime_error const& e)
    {
        cerr << e.what() << endl;
    }
}
