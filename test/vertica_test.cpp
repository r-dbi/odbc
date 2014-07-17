#include "test/basic_test.h"
#include <boost/test/test_case_template.hpp>

namespace
{
    basic_test test(NANODBC_TEXT("Driver=vertica;Servername=vertica;Port=5433;Database=reporting;UserName=dbadmin;Password=dbadmin;"));
}

BOOST_AUTO_TEST_SUITE(vertica)

BOOST_AUTO_TEST_CASE(simple_test)
{
    test.simple_test();
}

BOOST_AUTO_TEST_CASE(null_test)
{
    test.null_test();
}

BOOST_AUTO_TEST_CASE(string_test)
{
    test.string_test();
}

BOOST_AUTO_TEST_CASE_TEMPLATE(integral_test, T, basic_test::integral_test_types)
{
    test.integral_test_template<T>();
}

BOOST_AUTO_TEST_CASE(transaction_test)
{
    test.transaction_test();
}

BOOST_AUTO_TEST_CASE(exception_test)
{
    test.exception_test();
}

BOOST_AUTO_TEST_CASE(execute_multiple)
{
    test.execute_multiple();
}

BOOST_AUTO_TEST_CASE(execute_multiple_transaction)
{
    test.execute_multiple_transaction();
}

BOOST_AUTO_TEST_SUITE_END()
