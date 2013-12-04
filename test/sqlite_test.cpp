#include "nanodbc.h"

#define BOOST_TEST_MODULE nanodbc

#include <boost/test/unit_test.hpp>
#include <boost/test/test_case_template.hpp>
#include <boost/mpl/list.hpp>

using nanodbc::string_type;
using namespace std;

nanodbc::connection connect()
{
    return nanodbc::connection("Driver=sqlite;Database=nanodbc.db;");   
}

struct sqlite_fixture
{
    sqlite_fixture()
    : i(0)
    {

    }

    ~sqlite_fixture()
    {
        // system("rm nanodbc.db");
    }

    int i;
};

BOOST_FIXTURE_TEST_SUITE(s, sqlite_fixture)

BOOST_AUTO_TEST_CASE(simple_test)
{
    nanodbc::connection connection = connect();
    BOOST_CHECK(connection.connected());
    BOOST_CHECK(connection.native_dbc_handle());
    BOOST_CHECK(connection.native_env_handle());
    BOOST_CHECK_EQUAL(connection.transactions(), 0);
    BOOST_CHECK_EQUAL(connection.driver_name(), "sqlite3odbc.so");

    execute(connection, "drop table if exists simple_test;");
    execute(connection, "create table simple_test (a int, b varchar(10));");
    execute(connection, "insert into simple_test values (1, 'one');");
    execute(connection, "insert into simple_test values (2, 'two');");
    execute(connection, "insert into simple_test values (3, 'tri');");
    execute(connection, "insert into simple_test (b) values ('z');");
    nanodbc::result results = execute(connection, "select a, b from simple_test order by a;");

    BOOST_CHECK((bool)results);
    BOOST_CHECK_EQUAL(results.rows(), 0);
    BOOST_CHECK_EQUAL(results.columns(), 2);
    BOOST_CHECK_EQUAL(results.affected_rows(), 4);
    BOOST_CHECK_EQUAL(results.rowset_size(), 1);
    BOOST_CHECK_EQUAL(results.column_name(0), "a");
    BOOST_CHECK_EQUAL(results.column_name(1), "b");

    BOOST_CHECK(results.next());
    BOOST_CHECK_EQUAL(results.rows(), 1);
    BOOST_CHECK(results.is_null(0));
    BOOST_CHECK(results.is_null("a"));
    BOOST_CHECK_EQUAL(results.get<int>(0, -1), -1);
    BOOST_CHECK_EQUAL(results.get<int>("a", -1), -1);
    BOOST_CHECK_EQUAL(results.get<string_type>(0, "null"), "null");
    BOOST_CHECK_EQUAL(results.get<string_type>("a", "null"), "null");
    BOOST_CHECK_EQUAL(results.get<string_type>(1), "z");
    BOOST_CHECK_EQUAL(results.get<string_type>("b"), "z");

    BOOST_CHECK(results.next());
    BOOST_CHECK_EQUAL(results.get<int>(0), 1);
    BOOST_CHECK_EQUAL(results.get<int>("a"), 1);
    BOOST_CHECK_EQUAL(results.get<string_type>(1), "one");
    BOOST_CHECK_EQUAL(results.get<string_type>("b"), "one");

    nanodbc::result results_copy = results;

    BOOST_CHECK(results_copy.next());
    BOOST_CHECK_EQUAL(results_copy.get<int>(0, -1), 2);
    BOOST_CHECK_EQUAL(results_copy.get<int>("a", -1), 2);
    BOOST_CHECK_EQUAL(results_copy.get<string_type>(1), "two");
    BOOST_CHECK_EQUAL(results_copy.get<string_type>("b"), "two");

    BOOST_CHECK(results.position());

    nanodbc::result().swap(results_copy);

    BOOST_CHECK(results.next());
    BOOST_CHECK_EQUAL(results.get<string_type>(0), "3");
    BOOST_CHECK_EQUAL(results.get<string_type>("a"), "3");
    BOOST_CHECK_EQUAL(results.get<string_type>(1), "tri");
    BOOST_CHECK_EQUAL(results.get<string_type>("b"), "tri");

    BOOST_CHECK(!results.next());
    BOOST_CHECK(results.end());

    nanodbc::connection connection_copy(connection);

    connection.disconnect();
    BOOST_CHECK(!connection.connected());
    BOOST_CHECK(!connection_copy.connected());
}

BOOST_AUTO_TEST_SUITE_END()
