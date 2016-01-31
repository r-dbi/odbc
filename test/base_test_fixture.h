#ifndef NANODBC_TEST_BASE_TEST_FIXTURE_H
#define NANODBC_TEST_BASE_TEST_FIXTURE_H

#include "nanodbc.h"
#include <tuple>
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4244) // conversion from 'T1' to 'T2' possible loss of data
#endif

#if defined(_MSC_VER) && _MSC_VER <= 1800
    // These versions of Visual C++ do not yet support noexcept or override.
    #define NANODBC_NOEXCEPT
    #define NANODBC_OVERRIDE
#else
    #define NANODBC_NOEXCEPT noexcept
    #define NANODBC_OVERRIDE override
#endif

#ifdef NANODBC_USE_UNICODE
    #define NANODBC_TEXT(s) u ## s
#else
    #define NANODBC_TEXT(s) s
#endif

#ifdef NANODBC_USE_BOOST_CONVERT
    #include <boost/locale/encoding_utf.hpp>
#else
    #include <codecvt>
#endif

#ifdef _WIN32
// needs to be included above sql.h for windows
#define NOMINMAX
#include <windows.h>
#endif
#include <sql.h>
#include <sqlext.h>

struct base_test_fixture
{
    // To invoke a unit test over all integral types, use:
    //
    typedef std::tuple<
        nanodbc::string_type::value_type
        , short
        , unsigned short
        , int32_t
        , uint32_t
        , int64_t
        , uint64_t
        , float
        , double
        > integral_test_types;

    base_test_fixture()
    : connection_string_(get_connection_string_from_env())
    {
    }

    base_test_fixture(const nanodbc::string_type& connection_string)
    : connection_string_(connection_string)
    {
    }

    virtual ~base_test_fixture() NANODBC_NOEXCEPT
    {
    }

    // Utilities

    nanodbc::string_type connection_string_;

    nanodbc::connection connect()
    {
        return nanodbc::connection(connection_string_);
    }

    static void check_rows_equal(nanodbc::result results, int rows)
    {
        REQUIRE(results.next());
        REQUIRE(results.get<int>(0) == rows);
    }

    nanodbc::string_type get_connection_string_from_env() const
    {
        const char* env_name = "NANODBC_TEST_CONNSTR";
        char* env_value = nullptr;
        std::string connection_string;
        #ifdef _MSC_VER
            std::size_t env_len(0);
            errno_t err = _dupenv_s(&env_value, &env_len, env_name);
            if(!err && env_value)
            {
                connection_string = env_value;
                std::free(env_value);
            }
        #else
            env_value = std::getenv(env_name);
            if(!env_value) return nanodbc::string_type();
            connection_string = env_value;
        #endif

        #ifdef NANODBC_USE_UNICODE
            #ifdef NANODBC_USE_BOOST_CONVERT
                using boost::locale::conv::utf_to_utf;
                return utf_to_utf<char16_t>(connection_string.c_str()
                    , connection_string.c_str() + connection_string.size());
            #else
                return std::wstring_convert<
                    std::codecvt_utf8_utf16<char16_t>, char16_t>().from_bytes(connection_string);
            #endif
        #else
                return connection_string;
        #endif
    }

    bool contains_string(nanodbc::string_type const& str, nanodbc::string_type const& sub)
    {
        if (str.empty() || sub.empty())
            return false;

        return str.find(sub) != nanodbc::string_type::npos;
    }

    virtual void drop_table(nanodbc::connection& connection, const nanodbc::string_type& name) const
    {
        bool table_exists = true;
        try
        {
            // create empty result set as a poor man's portable "IF EXISTS" test
            nanodbc::result results = execute(connection,
                NANODBC_TEXT("SELECT * FROM ") + name + NANODBC_TEXT(" WHERE 0=1;"));
        }
        catch (...)
        {
            table_exists = false;
        }

        if (table_exists)
        {
            execute(connection, NANODBC_TEXT("DROP TABLE ") + name + NANODBC_TEXT(";"));
        }
    }

    // Test Cases

    void catalog_columns_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());
        nanodbc::catalog catalog(connection);

        // Successfully tested against SQL Server and PostgreSQL (9.x) only.
        // TODO: It needs to be tested against MySQL, Oracle and other DBMS. -- mloskot

        // Check we can iterate over any columns
        {
            nanodbc::catalog::columns columns = catalog.find_columns();
            long count = 0;
            while(columns.next())
            {
                // These values must not be NULL (returned as empty string)
                REQUIRE(!columns.column_name().empty());
                count++;
            }
            REQUIRE(count > 0);
        }

        // Find a table with known name and verify its known columns
        {
            // Determine DBMS-specific features, properties and values
            // NOTE: If handling DBMS-specific features become overly complicated,
            //       we may decided to remove such features from the tests.
            nanodbc::string_type binary_type_name;
            {
                nanodbc::string_type const dbms = connection.dbms_name();
                REQUIRE(!dbms.empty());
                if (contains_string(dbms, NANODBC_TEXT("SQLite")))
                {
                    binary_type_name = NANODBC_TEXT("blob");
                }
                else if (contains_string(dbms, NANODBC_TEXT("PostgreSQL")))
                {
                    binary_type_name = NANODBC_TEXT("bytea");
                }
                else
                {
                    binary_type_name = NANODBC_TEXT("varbinary"); // Oracle, MySQL, SQL Server,...standard type?
                }
            }
            REQUIRE(!binary_type_name.empty());

            nanodbc::string_type const table_name(NANODBC_TEXT("catalog_columns_test"));
            drop_table(connection, table_name);
            execute(connection, NANODBC_TEXT("create table ") + table_name + NANODBC_TEXT("(")
                + NANODBC_TEXT("c0 int PRIMARY KEY,")
                + NANODBC_TEXT("c1 smallint NOT NULL,")
                + NANODBC_TEXT("c2 float NULL,")
                + NANODBC_TEXT("c3 decimal(9, 3),")
                + NANODBC_TEXT("c4 date,") // seems more portable than datetime (SQL Server), timestamp (PostgreSQL, MySQL)
                + NANODBC_TEXT("c5 varchar(60) DEFAULT \'sample value\',")
                + NANODBC_TEXT("c6 varchar(120),")
                + NANODBC_TEXT("c7 text,")
                + NANODBC_TEXT("c8 ") + binary_type_name
                + NANODBC_TEXT(");")
                );

            // Check only SQL/ODBC standard properties, skip those which are driver-specific.
            nanodbc::catalog::columns columns = catalog.find_columns(NANODBC_TEXT("%"), table_name);

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c0"));
            REQUIRE(columns.sql_data_type() == SQL_INTEGER);
            REQUIRE(columns.column_size() == 10);
            REQUIRE(columns.decimal_digits() == 0);
            REQUIRE(columns.nullable() == SQL_NO_NULLS);
            REQUIRE(columns.table_name() == table_name); // assume common for the whole result set, check once
            REQUIRE(!columns.type_name().empty()); // data source dependant name, check once
            if (!columns.is_nullable().empty()) // nullability determined
                REQUIRE(columns.is_nullable() == NANODBC_TEXT("NO"));

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c1"));
            REQUIRE(columns.sql_data_type() == SQL_SMALLINT);
            REQUIRE(columns.column_size() == 5);
            REQUIRE(columns.decimal_digits() == 0);
            REQUIRE(columns.nullable() == SQL_NO_NULLS);
            if (!columns.is_nullable().empty()) // nullability determined
                REQUIRE(columns.is_nullable() == NANODBC_TEXT("NO"));

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c2"));
            REQUIRE(columns.sql_data_type() == SQL_FLOAT);
            if (columns.numeric_precision_radix() == 10)
                REQUIRE(columns.column_size() ==  17); // total number of digits allowed
            else
                REQUIRE(columns.column_size() ==  53); // total number of bits allowed
            REQUIRE(columns.nullable() == SQL_NULLABLE);
            if (!columns.is_nullable().empty()) // nullability determined
                REQUIRE(columns.is_nullable() == NANODBC_TEXT("YES"));

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c3"));
            REQUIRE((columns.sql_data_type() == SQL_DECIMAL || columns.sql_data_type() == SQL_NUMERIC));
            REQUIRE(columns.column_size() == 9);
            REQUIRE(columns.decimal_digits() == 3);
            REQUIRE(columns.nullable() == SQL_NULLABLE);
            if (!columns.is_nullable().empty()) // nullability determined
                REQUIRE(columns.is_nullable() == NANODBC_TEXT("YES"));

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c4"));
            REQUIRE(columns.sql_data_type() == SQL_DATE);
            REQUIRE(columns.column_size() == 10); // total number of characters required to display the value when it is converted to characters

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c5"));
            REQUIRE((columns.sql_data_type() == SQL_VARCHAR || columns.sql_data_type() == SQL_WVARCHAR));
            REQUIRE(columns.column_size() == 60);
            REQUIRE(contains_string(columns.column_default(), NANODBC_TEXT("\'sample value\'")));

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c6"));
            REQUIRE((columns.sql_data_type() == SQL_VARCHAR || columns.sql_data_type() == SQL_WVARCHAR));
            REQUIRE(columns.column_size() == 120);

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c7"));
            REQUIRE((columns.sql_data_type() == SQL_LONGVARCHAR || columns.sql_data_type() == SQL_WLONGVARCHAR));
            // PostgreSQL uses MaxLongVarcharSize=8190, which is configurable in odbc.ini
            REQUIRE((columns.column_size() == 2147483647 || columns.column_size() == 8190)); // TODO: confirm "text" max length

            REQUIRE(columns.next());
            REQUIRE(columns.column_name() == NANODBC_TEXT("c8"));
            REQUIRE(columns.sql_data_type() == SQL_VARBINARY);
            // SQL Server: if n is not specified in [var]binary(n), the default length is 1
            // PostgreSQL: bytea default length is reported as 255,
            // unless ByteaAsLongVarBinary=1 option is specified in connection string.
            REQUIRE(columns.column_size() > 0); // no need to test exact value

            // expect no more records
            REQUIRE(!columns.next());
        }
    }

    void catalog_primary_keys_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());
        nanodbc::catalog catalog(connection);

        // Successfully tested against SQL Server and PostgreSQL (9.x) only.
        // TODO: It needs to be tested against MySQL, Oracle and other DBMS. -- mloskot

        // Find a single-column primary key for table with known name
        {
            nanodbc::string_type const table_name(NANODBC_TEXT("catalog_primary_keys_simple_test"));
            drop_table(connection, table_name);
            execute(connection, NANODBC_TEXT("create table ") + table_name
                + NANODBC_TEXT("(i int NOT NULL, CONSTRAINT pk_simple_test PRIMARY KEY (i));"));

            nanodbc::catalog::primary_keys keys =  catalog.find_primary_keys(table_name);
            REQUIRE(keys.next());
            REQUIRE(keys.table_name() == table_name);
            REQUIRE(keys.column_name() == NANODBC_TEXT("i"));
            REQUIRE(keys.column_number() == 1);
            REQUIRE(keys.primary_key_name() == NANODBC_TEXT("pk_simple_test"));
            // expect no more records
            REQUIRE(!keys.next());
        }

        // Find a multi-column primary key for table with known name
        {
            nanodbc::string_type const table_name(NANODBC_TEXT("catalog_primary_keys_composite_test"));
            drop_table(connection, table_name);
            execute(connection, NANODBC_TEXT("create table ") + table_name
                + NANODBC_TEXT("(a int, b smallint, CONSTRAINT pk_composite_test PRIMARY KEY(a, b));"));

            nanodbc::catalog::primary_keys keys =  catalog.find_primary_keys(table_name);
            REQUIRE(keys.next());
            REQUIRE(keys.table_name() == table_name);
            REQUIRE(keys.column_name() == NANODBC_TEXT("a"));
            REQUIRE(keys.column_number() == 1);
            REQUIRE(keys.primary_key_name() == NANODBC_TEXT("pk_composite_test"));

            REQUIRE(keys.next());
            REQUIRE(keys.table_name() == table_name);
            REQUIRE(keys.column_name() == NANODBC_TEXT("b"));
            REQUIRE(keys.column_number() == 2);
            REQUIRE(keys.primary_key_name() == NANODBC_TEXT("pk_composite_test"));

            // expect no more records
            REQUIRE(!keys.next());
        }
    }

    void catalog_tables_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());
        nanodbc::catalog catalog(connection);

        // Successfully tested against SQL Server and PostgreSQL (9.x) only.
        // TODO: It needs to be tested against MySQL, Oracle and other DBMS. -- mloskot

        // Check we can iterate over any tables
        {
            nanodbc::catalog::tables tables = catalog.find_tables();
            long count = 0;
            while(tables.next())
            {
                // These two values must not be NULL (returned as empty string)
                REQUIRE(!tables.table_name().empty());
                REQUIRE(!tables.table_type().empty());
                count++;
            }
            REQUIRE(count > 0);
        }

        // Check if there are any tables (with catalog restriction)
        {
            nanodbc::string_type empty_name; // a placeholder, makes no restriction on the look-up
            nanodbc::catalog::tables tables = catalog.find_tables(empty_name, NANODBC_TEXT("TABLE"), empty_name, empty_name);
            long count = 0;
            while(tables.next())
            {
                // These two values must not be NULL (returned as empty string)
                REQUIRE(!tables.table_name().empty());
                REQUIRE(!tables.table_type().empty());
                count++;
            }
            REQUIRE(count > 0);
        }

        nanodbc::string_type const table_name(NANODBC_TEXT("catalog_tables_test"));

        // Find a table with known name
        {
            drop_table(connection, table_name);
            execute(connection, NANODBC_TEXT("create table ") + table_name + NANODBC_TEXT("(a int);"));

            // Use brute-force look-up
            {
                nanodbc::catalog::tables tables = catalog.find_tables();
                bool found = false;
                while(tables.next())
                {
                    if(table_name == tables.table_name())
                    {
                        REQUIRE(tables.table_type() == NANODBC_TEXT("TABLE"));
                        found = true;
                        break;
                    }
                }
                REQUIRE(found);
            }

            // Use SQLTables pattern search capabilities
            {
                nanodbc::catalog::tables tables = catalog.find_tables(table_name);
                // expect single record with the wanted table
                REQUIRE(tables.next());
                REQUIRE(tables.table_name() == table_name);
                REQUIRE(tables.table_type() == NANODBC_TEXT("TABLE"));
                // expect no more records
                REQUIRE(!tables.next());
            }
        }

        // Find a VIEW with known name
        {
            // Use SQLTables pattern search by name only (in any schema)
            {
                nanodbc::string_type const view_name(NANODBC_TEXT("catalog_tables_test_view"));
                try
                {
                    execute(connection, NANODBC_TEXT("DROP VIEW ") + view_name);
                }
                catch (...) {}
                execute(connection, NANODBC_TEXT("CREATE VIEW ") + view_name
                    + NANODBC_TEXT(" AS SELECT a FROM ") + table_name);

                nanodbc::catalog::tables tables = catalog.find_tables(view_name, NANODBC_TEXT("VIEW"));
                // expect single record with the wanted table
                REQUIRE(tables.next());
                REQUIRE(tables.table_name() == view_name);
                REQUIRE(tables.table_type() == NANODBC_TEXT("VIEW"));
                // expect no more records
                REQUIRE(!tables.next());

                // Clean up, otherwise source table can not be dropped and re-created
                execute(connection, NANODBC_TEXT("DROP VIEW ") + view_name);
            }

            // Use SQLTables pattern search by name inside given schema
            // TODO: Target other databases where INFORMATION_SCHEMA support is available.
            if (connection.dbms_name().find(NANODBC_TEXT("SQL Server")) != nanodbc::string_type::npos)
            {
                nanodbc::string_type const view_name(NANODBC_TEXT("TABLE_PRIVILEGES"));
                nanodbc::string_type const schema_name(NANODBC_TEXT("INFORMATION_SCHEMA"));
                nanodbc::catalog::tables tables = catalog.find_tables(view_name, NANODBC_TEXT("VIEW"), schema_name);
                // expect single record with the wanted table
                REQUIRE(tables.next());
                REQUIRE(tables.table_schema() == schema_name);
                REQUIRE(tables.table_name() == view_name);
                REQUIRE(tables.table_type() == NANODBC_TEXT("VIEW"));
                // expect no more records
                REQUIRE(!tables.next());
            }
        }
    }

    void dbms_info_test()
    {
        // A generic test to exercise the DBMS info API is callable.
        // DBMS-specific test (MySQL, SQLite, etc.) may perform extended checks.

        nanodbc::connection connection = connect();
        REQUIRE(!connection.dbms_name().empty());
        REQUIRE(!connection.dbms_version().empty());
    }

    void decimal_conversion_test()
    {
        nanodbc::connection connection = connect();
        nanodbc::result results;
        drop_table(connection, NANODBC_TEXT("decimal_conversion_test"));
        execute(connection, NANODBC_TEXT("create table decimal_conversion_test (d decimal(9, 3));"));
        execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (12345.987);"));
        execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (5.600);"));
        execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (1.000);"));
        execute(connection, NANODBC_TEXT("insert into decimal_conversion_test values (-1.333);"));
        results = execute(connection, NANODBC_TEXT("select * from decimal_conversion_test order by 1 desc;"));

        REQUIRE(results.next());
        REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("12345.987"));

        REQUIRE(results.next());
        REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("5.600"));

        REQUIRE(results.next());
        REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("1.000"));

        REQUIRE(results.next());
        REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("-1.333"));
    }

    void exception_test()
    {
        nanodbc::connection connection = connect();
        nanodbc::result results;

        REQUIRE_THROWS_AS(execute(connection, NANODBC_TEXT("THIS IS NOT VALID SQL!")), nanodbc::database_error);

        drop_table(connection, NANODBC_TEXT("exception_test"));
        execute(connection, NANODBC_TEXT("create table exception_test (i int);"));
        execute(connection, NANODBC_TEXT("insert into exception_test values (-10);"));
        execute(connection, NANODBC_TEXT("insert into exception_test values (null);"));

        results = execute(connection, NANODBC_TEXT("select * from exception_test where i = -10;"));

        REQUIRE(results.next());
        REQUIRE_THROWS_AS(results.get<nanodbc::date>(0), nanodbc::type_incompatible_error);
        REQUIRE_THROWS_AS(results.get<nanodbc::timestamp>(0), nanodbc::type_incompatible_error);

        results = execute(connection, NANODBC_TEXT("select * from exception_test where i is null;"));

        REQUIRE(results.next());
        REQUIRE_THROWS_AS(results.get<int>(0), nanodbc::null_access_error);
        REQUIRE_THROWS_AS(results.get<int>(42), nanodbc::index_range_error);

        nanodbc::statement statement(connection);
        REQUIRE(statement.open());
        REQUIRE(statement.connected());
        statement.close();
        REQUIRE_THROWS_AS(statement.prepare(NANODBC_TEXT("select * from exception_test;")), nanodbc::programming_error);
    }

    void execute_multiple_transaction_test()
    {
        nanodbc::connection connection = connect();
        nanodbc::statement statement;
        nanodbc::result results;

        statement.prepare(connection, NANODBC_TEXT("select 42;"));

        {
            nanodbc::transaction transaction(connection);
            results = statement.execute();
            results.next();
            REQUIRE(results.get<int>(0) == 42);
        }

        results = statement.execute();
        results.next();
        REQUIRE(results.get<int>(0) == 42);
    }

    void execute_multiple_test()
    {
        nanodbc::connection connection = connect();
        nanodbc::statement statement(connection);
        nanodbc::prepare(statement, NANODBC_TEXT("select 42;"));

        nanodbc::result results = statement.execute();
        results.next();

        results = statement.execute();
        results.next();
        REQUIRE(results.get<int>(0) == 42);

        results = statement.execute();
        results.next();
        REQUIRE(results.get<int>(0) == 42);
    }

    template<class T>
    void integral_test_template()
    {
        nanodbc::connection connection = connect();

        drop_table(connection, NANODBC_TEXT("integral_test"));
        execute(connection, NANODBC_TEXT("create table integral_test (i int, f float, d double precision);"));

        nanodbc::statement statement(connection);
        prepare(statement, NANODBC_TEXT("insert into integral_test (i, f, d) values (?, ?, ?);"));

        srand(0);
        const int32_t i = rand() % 5000;
        const float f = rand() / (rand() + 1.0);
        const float d = - rand() / (rand() + 1.0);

        short p = 0;
        statement.bind(p++, &i);
        statement.bind(p++, &f);
        statement.bind(p++, &d);

        REQUIRE(statement.connected());
        execute(statement);

        nanodbc::result results = execute(connection, NANODBC_TEXT("select * from integral_test;"));
        REQUIRE(results.next());

        // NOTE: Parentheses around REQURE() expressions are to silence error:
        //       suggest parentheses around comparison in operand of ‘==’ [-Werror=parentheses]
        T ref;
        p = 0;
        results.get_ref(p, ref);
        REQUIRE((ref == static_cast<T>(i)));
        REQUIRE((results.get<T>(p++) == Approx(static_cast<T>(i))));
        results.get_ref(p, ref);
        REQUIRE((static_cast<float>(ref) == Approx(static_cast<T>(f))));
        REQUIRE((static_cast<float>(results.get<T>(p++)) == Approx(static_cast<T>(f))));
        results.get_ref(p, ref);
        REQUIRE((static_cast<double>(ref) == Approx(static_cast<T>(d))));
        REQUIRE((static_cast<double>(results.get<T>(p++)) == Approx(static_cast<T>(d))));
    }

    template<class Fixture, class TypeList, size_t i = std::tuple_size<TypeList>::value - 1>
    struct foreach {
        static void run()
        {
            Fixture fixture;
            using type = typename std::tuple_element<i, TypeList>::type;
            fixture.template integral_test_template<type>();
            foreach<Fixture, TypeList, i - 1>::run();
        }
    };

    template<class Fixture, class TypeList>
    struct foreach<Fixture, TypeList, 0> {
        static void run()
        {
            Fixture fixture;
            using type = typename std::tuple_element<0, TypeList>::type;
            fixture.template integral_test_template<type>();
        }
    };

    template<class Fixture>
    void integral_test()
    {
        foreach<Fixture, integral_test_types>::run();
    }

    void move_test()
    {
        nanodbc::connection orig_connection = connect();
        drop_table(orig_connection, NANODBC_TEXT("move_test"));
        execute(orig_connection, NANODBC_TEXT("create table move_test (i int);"));
        execute(orig_connection, NANODBC_TEXT("insert into move_test values (10);"));

        nanodbc::connection new_connection = std::move(orig_connection);
        execute(new_connection, NANODBC_TEXT("insert into move_test values (30);"));
        execute(new_connection, NANODBC_TEXT("insert into move_test values (20);"));

        nanodbc::result orig_results = execute(new_connection,
            NANODBC_TEXT("select i from move_test order by i desc;")
        );
        REQUIRE(orig_results.next());
        REQUIRE(orig_results.get<int>(0) == 30);
        REQUIRE(orig_results.next());
        REQUIRE(orig_results.get<int>(0) == 20);

        nanodbc::result new_results = std::move(orig_results);
        REQUIRE(new_results.next());
        REQUIRE(new_results.get<int>(0) == 10);
    }

    void null_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());

        drop_table(connection, NANODBC_TEXT("null_test"));
        execute(connection, NANODBC_TEXT("create table null_test (a int, b varchar(10));"));

        nanodbc::statement statement(connection);

        prepare(statement, NANODBC_TEXT("insert into null_test (a, b) values (?, ?);"));
        statement.bind_null(0);
        statement.bind_null(1);
        execute(statement);

        prepare(statement, NANODBC_TEXT("insert into null_test (a, b) values (?, ?);"));
        statement.bind_null(0, 2);
        statement.bind_null(1, 2);
        execute(statement, 2);

        nanodbc::result results = execute(connection, NANODBC_TEXT("select a, b from null_test order by a;"));

        REQUIRE(results.next());
        REQUIRE(results.is_null(0));
        REQUIRE(results.is_null(1));

        REQUIRE(results.next());
        REQUIRE(results.is_null(0));
        REQUIRE(results.is_null(1));

        REQUIRE(results.next());
        REQUIRE(results.is_null(0));
        REQUIRE(results.is_null(1));

        REQUIRE(!results.next());
    }

    void simple_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());
        REQUIRE(connection.native_dbc_handle());
        REQUIRE(connection.native_env_handle());
        REQUIRE(connection.transactions() == std::size_t(0));

        drop_table(connection, NANODBC_TEXT("simple_test"));
        execute(connection, NANODBC_TEXT("create table simple_test (sort_order int, a int, b varchar(10));"));
        execute(connection, NANODBC_TEXT("insert into simple_test values (2, 1, 'one');"));
        execute(connection, NANODBC_TEXT("insert into simple_test values (3, 2, 'two');"));
        execute(connection, NANODBC_TEXT("insert into simple_test values (4, 3, 'tri');"));
        execute(connection, NANODBC_TEXT("insert into simple_test values (1, NULL, 'z');"));

        {
            nanodbc::result results = execute(connection, NANODBC_TEXT("select a, b from simple_test order by sort_order;"));
            REQUIRE((bool)results);
            REQUIRE(results.rows() == 0);
            REQUIRE(results.columns() == 2);

            // From MSDN on SQLRowCount:
            // Row count is either the number of rows affected by the request
            // or -1 if the number of affected rows is not available.
            // For other statements and functions, the driver may define the value returned (...)
            // some data sources may be able to return the number of rows returned by a SELECT statement.
            const bool affected_four = results.affected_rows() == 4;
            const bool affected_zero = results.affected_rows() == 0;
            const bool affected_negative_one = results.affected_rows() == -1;
            REQUIRE(affected_four + affected_zero + affected_negative_one);
            if(!(affected_four + affected_zero + affected_negative_one)) {
                // Provide more verbose output if one of the above terms is false:
                CHECK(affected_four);
                CHECK(affected_zero);
                CHECK(affected_negative_one);
            }

            REQUIRE(results.rowset_size() == 1);
            REQUIRE(results.column_name(0) == NANODBC_TEXT("a"));
            REQUIRE(results.column_name(1) == NANODBC_TEXT("b"));

            // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
            REQUIRE(results.next());
            // row = (null)|z
            // .....................................................................................
            REQUIRE(results.rows() == 1);
            REQUIRE(results.is_null(0));
            REQUIRE(results.is_null(NANODBC_TEXT("a")));
            REQUIRE(results.get<int>(0, -1) == -1);
            REQUIRE(results.get<int>(NANODBC_TEXT("a"), -1) == -1);
            REQUIRE(results.get<nanodbc::string_type>(0, NANODBC_TEXT("null")) == NANODBC_TEXT("null"));
            REQUIRE(results.get<nanodbc::string_type>(NANODBC_TEXT("a"), NANODBC_TEXT("null")) == NANODBC_TEXT("null"));
            REQUIRE(results.get<nanodbc::string_type>(1) == NANODBC_TEXT("z"));
            REQUIRE(results.get<nanodbc::string_type>(NANODBC_TEXT("b")) == NANODBC_TEXT("z"));

            int ref_int;
            results.get_ref(0, -1, ref_int);
            REQUIRE(ref_int == -1);
            results.get_ref(NANODBC_TEXT("a"), -2, ref_int);
            REQUIRE(ref_int == -2);

            nanodbc::string_type ref_str;
            results.get_ref<nanodbc::string_type>(0, NANODBC_TEXT("null"), ref_str);
            REQUIRE(ref_str == NANODBC_TEXT("null"));
            results.get_ref<nanodbc::string_type>(NANODBC_TEXT("a"), NANODBC_TEXT("null2"), ref_str);
            REQUIRE(ref_str == NANODBC_TEXT("null2"));

            // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
            REQUIRE(results.next());
            // row = 1|one
            // .....................................................................................
            REQUIRE(results.get<int>(0) == 1);
            REQUIRE(results.get<int>(NANODBC_TEXT("a")) == 1);
            REQUIRE(results.get<nanodbc::string_type>(1) == NANODBC_TEXT("one"));
            REQUIRE(results.get<nanodbc::string_type>(NANODBC_TEXT("b")) == NANODBC_TEXT("one"));

            nanodbc::result results_copy = results;

            // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
            REQUIRE(results_copy.next());
            // row = 2|two
            // .....................................................................................
            REQUIRE(results_copy.get<int>(0, -1) == 2);
            REQUIRE(results_copy.get<int>(NANODBC_TEXT("a"), -1) == 2);
            REQUIRE(results_copy.get<nanodbc::string_type>(1) == NANODBC_TEXT("two"));
            REQUIRE(results_copy.get<nanodbc::string_type>(NANODBC_TEXT("b")) == NANODBC_TEXT("two"));

            // FIXME: not supported by the default SQL_CURSOR_FORWARD_ONLY
            // and will require SQL_ATTR_CURSOR_TYPE set to SQL_CURSOR_STATIC at least.
            //REQUIRE(results.position());

            nanodbc::result().swap(results_copy);

            // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
            REQUIRE(results.next());
            // row = 3|tri
            // .....................................................................................
            REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("3"));
            REQUIRE(results.get<nanodbc::string_type>(NANODBC_TEXT("a")) == NANODBC_TEXT("3"));
            REQUIRE(results.get<nanodbc::string_type>(1) == NANODBC_TEXT("tri"));
            REQUIRE(results.get<nanodbc::string_type>(NANODBC_TEXT("b")) == NANODBC_TEXT("tri"));

            REQUIRE(!results.next());
            REQUIRE(results.end());
        }

        nanodbc::connection connection_copy(connection);

        connection.disconnect();
        REQUIRE(!connection.connected());
        REQUIRE(!connection_copy.connected());
    }

    void string_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());
        REQUIRE(connection.native_dbc_handle());
        REQUIRE(connection.native_env_handle());
        REQUIRE(connection.transactions() == std::size_t(0));

        const nanodbc::string_type name = NANODBC_TEXT("Fred");

        drop_table(connection, NANODBC_TEXT("string_test"));
        execute(connection, NANODBC_TEXT("create table string_test (s varchar(10));"));

        nanodbc::statement query(connection);
        prepare(query, NANODBC_TEXT("insert into string_test(s) values(?)"));
        query.bind(0, name.c_str());
        nanodbc::execute(query);

        nanodbc::result results = execute(connection, NANODBC_TEXT("select s from string_test;"));
        REQUIRE(results.next());
        REQUIRE(results.get<nanodbc::string_type>(0) == NANODBC_TEXT("Fred"));

        nanodbc::string_type ref;
        results.get_ref(0, ref);
        REQUIRE(ref == name);
    }

    void transaction_test()
    {
        nanodbc::connection connection = connect();
        REQUIRE(connection.connected());

        drop_table(connection, NANODBC_TEXT("transaction_test"));
        execute(connection, NANODBC_TEXT("create table transaction_test (i int);"));

        nanodbc::statement statement(connection);
        prepare(statement, NANODBC_TEXT("insert into transaction_test (i) values (?);"));

        static const int elements = 10;
        int data[elements] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        statement.bind(0, data, elements);
        execute(statement, elements);

        static const nanodbc::string_type::value_type* query = NANODBC_TEXT("select count(1) from transaction_test;");

        check_rows_equal(execute(connection, query), 10);

        {
            nanodbc::transaction transaction(connection);
            execute(connection, NANODBC_TEXT("delete from transaction_test;"));
            check_rows_equal(execute(connection, query), 0);
            // ~transaction() calls rollback()
        }

        check_rows_equal(execute(connection, query), 10);

        {
            nanodbc::transaction transaction(connection);
            execute(connection, NANODBC_TEXT("delete from transaction_test;"));
            check_rows_equal(execute(connection, query), 0);
            transaction.rollback();
        }

        check_rows_equal(execute(connection, query), 10);

        {
            nanodbc::transaction transaction(connection);
            execute(connection, NANODBC_TEXT("delete from transaction_test;"));
            check_rows_equal(execute(connection, query), 0);
            transaction.commit();
        }

        check_rows_equal(execute(connection, query), 0);
    }

    void while_not_end_iteration_test()
    {
        nanodbc::connection connection = connect();
        drop_table(connection, NANODBC_TEXT("while_not_end_iteration_test"));
        execute(connection, NANODBC_TEXT("create table while_not_end_iteration_test (i int);"));
        execute(connection, NANODBC_TEXT("insert into while_not_end_iteration_test values (1);"));
        execute(connection, NANODBC_TEXT("insert into while_not_end_iteration_test values (2);"));
        execute(connection, NANODBC_TEXT("insert into while_not_end_iteration_test values (3);"));
        nanodbc::result results = execute(connection, NANODBC_TEXT("select * from while_not_end_iteration_test order by 1 desc;"));
        int i = 3;
        while(!results.end())
        {
            results.next();
            REQUIRE(results.get<int>(0) == i--);
        }
    }

    void while_next_iteration_test()
    {
        nanodbc::connection connection = connect();
        drop_table(connection, NANODBC_TEXT("while_next_iteration_test"));
        execute(connection, NANODBC_TEXT("create table while_next_iteration_test (i int);"));
        execute(connection, NANODBC_TEXT("insert into while_next_iteration_test values (1);"));
        execute(connection, NANODBC_TEXT("insert into while_next_iteration_test values (2);"));
        execute(connection, NANODBC_TEXT("insert into while_next_iteration_test values (3);"));
        nanodbc::result results = execute(connection, NANODBC_TEXT("select * from while_next_iteration_test order by 1 desc;"));
        int i = 3;
        while(results.next())
        {
            REQUIRE(results.get<int>(0) == i--);
        }
    }
};

#ifdef _MSC_VER
#pragma warning(pop)
#endif

#endif // NANODBC_TEST_BASIC_TEST_H
