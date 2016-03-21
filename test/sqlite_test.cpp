#define CATCH_CONFIG_MAIN
#include "catch.hpp"

#include "test/base_test_fixture.h"
#include <cstdio>

namespace
{
    // According to the sqliteodbc documentation,
    // driver name is different on Windows and Unix.
    #ifdef _WIN32
        const nanodbc::string_type driver_name(NANODBC_TEXT("SQLite3 ODBC Driver"));
    #else
        const nanodbc::string_type driver_name(NANODBC_TEXT("SQLite3"));
    #endif
    const nanodbc::string_type connection_string
        = NANODBC_TEXT("Driver=") + driver_name
        + NANODBC_TEXT(";Database=nanodbc.db;");

    struct sqlite_fixture : public base_test_fixture
    {
        sqlite_fixture()
        : base_test_fixture(connection_string)
        {
            sqlite_cleanup(); // in case prior test exited without proper cleanup
        }

        virtual ~sqlite_fixture() NANODBC_NOEXCEPT
        {
            sqlite_cleanup();
        }

        void sqlite_cleanup() NANODBC_NOEXCEPT
        {
            std::remove("nanodbc.db");
        }
    };
}

// NOTE: No catlog_* tests; not supported by SQLite.

TEST_CASE_METHOD(sqlite_fixture, "blob_test", "[sqlite][blob]")
{
    blob_test();
}

TEST_CASE_METHOD(sqlite_fixture, "dbms_info_test", "[sqlite][dmbs][metadata][info]")
{
    dbms_info_test();

    // Additional SQLite-specific checks
    nanodbc::connection connection = connect();
    REQUIRE(connection.dbms_name() == NANODBC_TEXT("SQLite"));
}

TEST_CASE_METHOD(sqlite_fixture, "decimal_conversion_test", "[sqlite][decimal][conversion]")
{
    // SQLite ODBC driver requires dedicated test.
    // The driver converts SQL DECIMAL value to C float value
    // without preserving DECIMAL(N,M) dimensions
    // and strips any trailing zeros.
    nanodbc::connection connection = connect();
    nanodbc::result results;

    drop_table(connection, NANODBC_TEXT("decimal_conversion_test"));
    execute(connection, NANODBC_TEXT("create table decimal_conversion_test (d decimal(9, 3));"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (12345.987);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (5.6);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (1);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (-1.333);"));
    results = execute(connection, NANODBC_TEXT("select * from decimal_conversion_test order by 1 desc;"));

    REQUIRE(results.next());
    REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("12345.987"));

    REQUIRE(results.next());
    REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("5.6"));

    REQUIRE(results.next());
    REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("1"));

    REQUIRE(results.next());
    REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("-1.333"));
}

TEST_CASE_METHOD(sqlite_fixture, "exception_test", "[sqlite][exception]")
{
    exception_test();
}

TEST_CASE_METHOD(sqlite_fixture, "execute_multiple_transaction_test", "[sqlite][execute][transaction]")
{
    execute_multiple_transaction_test();
}

TEST_CASE_METHOD(sqlite_fixture, "execute_multiple_test", "[sqlite][execute]")
{
    execute_multiple_test();
}

TEST_CASE_METHOD(sqlite_fixture, "integral_test", "[sqlite][integral]")
{
    integral_test<sqlite_fixture>();
}

TEST_CASE_METHOD(sqlite_fixture, "move_test", "[sqlite][move]")
{
    move_test();
}

TEST_CASE_METHOD(sqlite_fixture, "null_test", "[sqlite][null]")
{
    null_test();
}

TEST_CASE_METHOD(sqlite_fixture, "simple_test", "[sqlite]")
{
    simple_test();
}

TEST_CASE_METHOD(sqlite_fixture, "string_test", "[sqlite][string]")
{
    string_test();
}

TEST_CASE_METHOD(sqlite_fixture, "transaction_test", "[sqlite][transaction]")
{
    transaction_test();
}

TEST_CASE_METHOD(sqlite_fixture, "while_not_end_iteration_test", "[sqlite][looping]")
{
    while_not_end_iteration_test();
}

TEST_CASE_METHOD(sqlite_fixture, "while_next_iteration_test", "[sqlite][looping]")
{
    while_next_iteration_test();
}
