#define CATCH_CONFIG_MAIN
#include "catch.hpp"

#include "test/base_test_fixture.h"
#include <cstdio>
#include <cstdlib>

namespace
{
    struct mysql_fixture : public base_test_fixture
    {
        mysql_fixture()
        : base_test_fixture(/* connecting string from NANODBC_TEST_CONNSTR environment variable)*/)
        {
        }

        virtual ~mysql_fixture() NANODBC_NOEXCEPT
        {
        }
    };
}

// FIXME: No catlog_* tests for MySQL. Not supported?

TEST_CASE_METHOD(mysql_fixture, "dbms_info_test", "[mysql][dmbs][metadata][info]")
{
    dbms_info_test();
}

TEST_CASE_METHOD(mysql_fixture, "decimal_conversion_test", "[mysql][decimal][conversion]")
{
    decimal_conversion_test();
}

TEST_CASE_METHOD(mysql_fixture, "exception_test", "[mysql][exception]")
{
    exception_test();
}

TEST_CASE_METHOD(mysql_fixture, "execute_multiple_transaction_test", "[mysql][execute][transaction]")
{
    execute_multiple_transaction_test();
}

TEST_CASE_METHOD(mysql_fixture, "execute_multiple_test", "[mysql][execute]")
{
    execute_multiple_test();
}

TEST_CASE_METHOD(mysql_fixture, "integral_test", "[mysql][integral]")
{
    integral_test<mysql_fixture>();
}

TEST_CASE_METHOD(mysql_fixture, "move_test", "[mysql][move]")
{
    move_test();
}

TEST_CASE_METHOD(mysql_fixture, "null_test", "[mysql][null]")
{
    null_test();
}

TEST_CASE_METHOD(mysql_fixture, "simple_test", "[mysql]")
{
    simple_test();
}

TEST_CASE_METHOD(mysql_fixture, "string_test", "[mysql][string]")
{
    string_test();
}

TEST_CASE_METHOD(mysql_fixture, "transaction_test", "[mysql][transaction]")
{
    transaction_test();
}

TEST_CASE_METHOD(mysql_fixture, "while_not_end_iteration_test", "[mysql][looping]")
{
    while_not_end_iteration_test();
}

TEST_CASE_METHOD(mysql_fixture, "while_next_iteration_test", "[mysql][looping]")
{
    while_next_iteration_test();
}
