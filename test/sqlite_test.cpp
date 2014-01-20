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
        std::remove("nanodbc.db");
    }

    int i;
};

typedef boost::mpl::list<
    string_type::value_type
    , short
    , unsigned short
    , int32_t
    , uint32_t
    , int64_t
    , uint64_t
    , float
    , double
    > integral_test_types;

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

BOOST_AUTO_TEST_CASE(string_test)
{
    nanodbc::connection connection = connect();
    BOOST_CHECK(connection.connected());
    BOOST_CHECK(connection.native_dbc_handle());
    BOOST_CHECK(connection.native_env_handle());
    BOOST_CHECK_EQUAL(connection.transactions(), 0);
    BOOST_CHECK_EQUAL(connection.driver_name(), "sqlite3odbc.so");

    const std::string name = "Fred";

    execute(connection, "drop table if exists string_test;");
    execute(connection, "create table string_test (s varchar(10));");

    nanodbc::statement query(connection);
    prepare(query, "insert into string_test(s) values(?)");
    query.bind(0, name.c_str());
    nanodbc::execute(query);

    nanodbc::result results = execute(connection, "select s from string_test;");
    BOOST_CHECK(results.next());
    BOOST_CHECK_EQUAL(results.get<std::string>(0), "Fred");
}

BOOST_AUTO_TEST_CASE_TEMPLATE(integral_test, T, integral_test_types)
{
    nanodbc::connection connection = connect();

    execute(connection, "drop table if exists integral_test;");
    execute(connection, "create table integral_test (i int, f float, d double, c char);");

    nanodbc::statement statement(connection);
    prepare(statement, "insert into integral_test (i, f, d, c) values (?, ?, ?, ?);");

    srand(0);
    const int32_t i = rand() % 5000;
    const float f = rand() / (rand() + 1.0);
    const double d = - rand() / (rand() + 1.0);
    const char c = rand() % 256;

    short p = 0;
    statement.bind(p++, &i);
    statement.bind(p++, &f);
    statement.bind(p++, &d);
    statement.bind(p++, &c);

    BOOST_CHECK(statement.connected());
    execute(statement);

    nanodbc::result results = execute(connection, "select * from integral_test;");
    BOOST_CHECK(results.next());

    p = 0;
    BOOST_CHECK_EQUAL(results.get<T>(p++), static_cast<T>(i));
    BOOST_CHECK_CLOSE(static_cast<float>(results.get<T>(p++)), static_cast<T>(f), 1e-6);
    BOOST_CHECK_CLOSE(static_cast<double>(results.get<T>(p++)), static_cast<T>(d), 1e-6);
    BOOST_CHECK_EQUAL(results.get<T>(p++), static_cast<T>(c));
}

BOOST_AUTO_TEST_SUITE_END()
