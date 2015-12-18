#include "test/basic_test.h"
#include <boost/test/test_case_template.hpp>
#include <cstdio>

namespace
{
    struct sqlite_fixture
    {
        sqlite_fixture()
        {
        }

        ~sqlite_fixture()
        {
            std::remove("nanodbc.db");
        }
    };

    // According to the sqliteodbc documentation,
    // driver name is different on Windows and Unix.
#ifdef _WIN32
    const nanodbc::string_type driver_name(NANODBC_TEXT("SQLite3 ODBC Driver"));
#else
    const nanodbc::string_type driver_name(NANODBC_TEXT("sqlite"));
#endif
    const nanodbc::string_type connection_string
        = NANODBC_TEXT("Driver=") + driver_name
        + NANODBC_TEXT(";Database=nanodbc.db;");
    basic_test test(connection_string);
}

BOOST_FIXTURE_TEST_SUITE(sqlite, sqlite_fixture)

BOOST_AUTO_TEST_CASE(decimal_conversion_test)
{
    // SQLite ODBC driver requires dedicated test.
    // The driver converts SQL DECIMAL value to C float value
    // without preserving DECIMAL(N,M) dimensions
    // and strips any trailing zeros.
    nanodbc::connection connection = test.connect();
    nanodbc::result results;
    execute(connection, NANODBC_TEXT("drop table if exists decimal_conversion_test;"));
    execute(connection, NANODBC_TEXT("create table decimal_conversion_test (d decimal(9, 3));"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (12345.987);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (5.6);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (1);"));
    execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (-1.333);"));
    results = execute(connection, NANODBC_TEXT("select * from decimal_conversion_test order by 1 desc;"));

    BOOST_CHECK(results.next());
    BOOST_CHECK(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("12345.987"));

    BOOST_CHECK(results.next());
    BOOST_CHECK(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("5.6"));

    BOOST_CHECK(results.next());
    BOOST_CHECK(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("1"));

    BOOST_CHECK(results.next());
    BOOST_CHECK(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("-1.333"));
}

BOOST_AUTO_TEST_CASE(exception_test)
{
    test.exception_test();
}

BOOST_AUTO_TEST_CASE(execute_multiple_transaction_test)
{
    test.execute_multiple_transaction_test();
}

BOOST_AUTO_TEST_CASE(execute_multiple_test)
{
    test.execute_multiple_test();
}

BOOST_AUTO_TEST_CASE_TEMPLATE(integral_test, T, basic_test::integral_test_types)
{
    test.integral_test_template<T>();
}

#ifndef BOOST_NO_RVALUE_REFERENCES
    BOOST_AUTO_TEST_CASE(move_test)
    {
        test.move_test();
    }
#endif

BOOST_AUTO_TEST_CASE(null_test)
{
    test.null_test();
}

BOOST_AUTO_TEST_CASE(simple_test)
{
    test.simple_test();
}

BOOST_AUTO_TEST_CASE(string_test)
{
    test.string_test();
}

BOOST_AUTO_TEST_CASE(transaction_test)
{
    test.transaction_test();
}

BOOST_AUTO_TEST_CASE(while_not_end_iteration_test)
{
    test.while_not_end_iteration_test();
}

BOOST_AUTO_TEST_CASE(while_next_iteration_test)
{
    test.while_next_iteration_test();
}

BOOST_AUTO_TEST_SUITE_END()
