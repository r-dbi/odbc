#include <algorithm>
#include <array>
#include <codecvt>
#include <cstring>
#include <iostream>
#include <locale>
#include <stdexcept>
#include <string>
#include "nanodbc.h"
using namespace nanodbc;

#ifndef NANODBC_TEXT
#ifdef NANODBC_USE_UNICODE
#define NANODBC_TEXT(s) L ## s
#else
#define NANODBC_TEXT(s) s
#endif
#endif

#ifdef NANODBC_USE_UNICODE
inline nanodbc::string_type convert(std::string const & in)
{
    std::wstring out;
    out = std::wstring_convert<std::codecvt_utf8<wchar_t>>().from_bytes(in);
    return out;
}
#else
inline nanodbc::string_type convert(std::string const & in)
{
    return in;
}
#endif

#ifdef NANODBC_USE_UNICODE
auto& console = std::wcout;
#else
auto& console = std::cout;
#endif

void usage(std::ostream& out, std::string const& binary_name)
{
    out << "usage: " << binary_name << " connection_string" << std::endl;
}

int main(int argc, char* argv[])
{
    if(argc != 2)
    {
        char* app_name = std::strrchr(argv[0], '/');
        app_name = app_name ? app_name + 1 : argv[0];
        if(0 == std::strncmp(app_name, "lt-", 3))
            app_name += 3; // remove libtool prefix
        usage(std::cerr, app_name);
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
            } catch (std::runtime_error const&) {}

            execute(conn, NANODBC_TEXT("create table rowset_iteration (i int);"));
        }

        // Insert data
        {
            statement stmt(conn);
            prepare(stmt, NANODBC_TEXT("insert into rowset_iteration (i) values (?);"));
            std::array<int, 5> const numbers = { 100, 80, 60, 40, 20 };
            stmt.bind(0, numbers.data(), numbers.size());
            transact(stmt, static_cast<long>(numbers.size()));
        }

        // Select and fetch
        long batch_size = 1; // tweak to play with number of ODBC fetch calls
        nanodbc::result result = execute(conn, NANODBC_TEXT(
            "SELECT i FROM rowset_iteration ORDER BY i DESC;"), batch_size);
        for (int i = 1; result.next(); ++i)
        {
            console << i
                << NANODBC_TEXT("(") << result.rows()
                << NANODBC_TEXT("/") << result.rowset_size()
                << NANODBC_TEXT("):")
                << result.get<int>(0)
                << std::endl;
        }
    }
    catch (std::runtime_error const& e)
    {
        std::cerr << e.what() << std::endl;
    }
}
