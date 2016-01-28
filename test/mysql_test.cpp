#include "test/basic_test.h"
#include <boost/test/test_case_template.hpp>
#include <cstdio>
#include <cstdlib>

namespace
{
    struct odbc_fixture
    {
        odbc_fixture()
        {
        }

        ~odbc_fixture()
        {
        }
    };

    // Reads connection string from default configuration source
    // (e.g. NANODBC_TEST_CONNSTR environment variable)
    basic_test test;
}

BOOST_FIXTURE_TEST_SUITE(odbc, odbc_fixture)

BOOST_AUTO_TEST_CASE(dbms_info_test)
{
    test.dbms_info_test();
}

BOOST_AUTO_TEST_CASE(decimal_conversion_test)
{
    test.decimal_conversion_test();
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
