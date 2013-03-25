Synopsis
=======
A very small C++ wrapper for the native C ODBC API. For all the gory details see the [source level documentation](https://nanodbc.googlecode.com/hg/doc/index.html)! Developed by Amy Troschinetz.

Rationale
=======
Nanodbc originally began as a simple fork of [TinyODBC](http://code.google.com/p/tiodbc/) with some additional features. Eventually it grew to the point where it made sense to break with many of the basic underlaying design decisions of TinyODBC and completely refactor much of the codebase. Other projects that have had influence on nanodbc include [SimpleDB](http://simpledb.sourceforge.net), [pyodbc](http://code.google.com/p/pyodbc/, [Database Template Library](http://dtemplatelib.sourceforge.net), and [GSODBC](http://www.codeguru.com/mfc_database/gsodbc.html).

Why should you use nanodbc?

  * Small! Just like TinyODBC, nanodbc is small. Just one header and one implementation file.
  * Simple! There are only a handful of significant classes to learn.
  * Portable! Nanodbc uses  only standard C++ headers in addition to the ODBC API headers.
  * Robust! Where it makes sense, error handling is done with exceptions rather than return codes.
  * Features! Nanodbc supports ODBC 3, SQLDriverConnect(), Transactions, Bound Parameters, Bulk Operations, and much more.
  * Documented! I have tried to provide very clean and useful documentation with example usage.
  * Active! I am currently actively using and developing nanodbc so I hope to add more and more features all the time.

Download
=======
  * [Download nanodbc.h](https://raw.github.com/lexicalunit/nanodbc/master/nanodbc.h)
  * [Download nanodbc.cpp](https://raw.github.com/lexicalunit/nanodbc/master/nanodbc.cpp)
  * [Source level documentation](http://htmlpreview.github.com/?https://github.com/lexicalunit/nanodbc/blob/master/doc/index.html) Provided by htmlpreview.github.com.

Todo
=======
  * Blob support
  * Unit tests
  * Verify unicode support
  * Testing on many different systems
  * Testing with many different ODBC drivers

Example
=======
```cpp
#include "nanodbc.h"
#include <iostream>
#include <vector>

using namespace std;

template<class T>
void show(nanodbc::result results)
{
    const short columns = results.columns();
    long rows_displayed = 0;

    cout << "\nDisplaying " << results.affected_rows() << " rows "
         << "(" << results.rowset_size() << " fetched at a time):" << endl;

    // show the column names
    cout << "row\t";
    for(short i = 0; i < columns; ++i)
        cout << results.column_name(i) << "\t";
    cout << endl;

    // show the column data for each row
    while(results.next())
    {
        cout << rows_displayed++ << "\t";
        for(short col = 0; col < columns; ++col)
        {
            if(results.is_null(col))
                cout << "(null)";
            else
                cout << "(" << results.get<T>(col) << ")";
            cout << "\t";
        }
        cout << endl;
    }
}

nanodbc::result foo(nanodbc::connection& connection, const string& query)
{
    nanodbc::statement statement;
    return statement.execute_direct(connection, query);
    // notice that statement will be destructed here, but the result object
    // will keep the statement resources alive until we are done with them
}

int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        cerr << "please provide a connection string" << endl;
        return 1;
    }

    try
    {
        // Establishing connections
        const string connection_string = argv[1];
        nanodbc::connection connection(connection_string);
        // or nanodbc::connection connection(connection_string, timeout_seconds);
        // or nanodbc::connection connection("data source name", "username", "password");
        // or nanodbc::connection connection("data source name", "username", "password", timeout_seconds);
        cout << "Connected with driver " << connection.driver_name() << endl;

        nanodbc::statement statement;
        nanodbc::result results;

        // Direct execution
        statement.execute_direct(connection, "drop table if exists public.example_table;");
        statement.execute_direct(connection, "create table public.example_table (a int, b varchar(10));");
        statement.execute_direct(connection, "insert into public.example_table values (1, 'one');");
        statement.execute_direct(connection, "insert into public.example_table values (2, 'two');");
        statement.execute_direct(connection, "insert into public.example_table values (3, 'tri');");
        foo(connection, "insert into public.example_table (b) values ('z');");
        results = foo(connection, "select * from public.example_table;");
        show<string>(results);

        // Direct execution, bulk fetching 2 rows at a time
        results = statement.execute_direct(connection, "select * from public.example_table;", 2);
        show<string>(results);

        // Binding parameters
        statement.prepare(connection, "insert into public.example_table (a, b) values (?, ?);");
        const int eight_int = 8;
        statement.bind_parameter(0, &eight_int);
        const string eight_str = "eight";
        statement.bind_parameter(1, eight_str.c_str());
        statement.execute();

        statement.prepare(connection, "select * from public.example_table where a = ?;");
        statement.bind_parameter(0, &eight_int);
        results = statement.execute();
        show<string>(results);

        // Transactions
        {
            cout << "\ndeleting all rows ... " << flush;
            nanodbc::transaction transaction(connection);
            statement.execute_direct(connection, "delete from public.example_table;");
            // transaction will be rolled back if we don't call transaction.commit()
        }
        results = foo(connection, "select count(1) from public.example_table;");
        results.next();
        cout << "still have " << results.get<int>(0) << " rows!" << endl;

        // Bulk inserting
        statement.prepare(connection, "insert into public.example_table (a, b) values (10, ?);");
        const char values[][10] = {"this", "is", "a", "test"};
        statement.bind_parameter(0, values);
        {
            nanodbc::transaction transaction(connection);
            statement.execute(4);
            transaction.commit();
        }
        results = statement.execute_direct(connection, "select * from public.example_table where a = 10;");
        show<string>(results);

        // Bulk inserting
        {
            statement.execute_direct(connection, "drop table if exists public.batch_insert_test;");
            statement.execute_direct(connection, "create table public.batch_insert_test (y int, z float);");
            statement.prepare(connection, "insert into public.batch_insert_test (y, z) values (?, ?);");

            const size_t data_count = 4;
            
            int ydata[data_count] = { 1, 2, 3, 4 };
            statement.bind_parameter(0, ydata);

            float zdata[data_count] = { 1.1, 2.2, 3.3, 4.4 };
            statement.bind_parameter(1, zdata);

            nanodbc::transaction transaction(connection);
            statement.execute(data_count);
            transaction.commit();
 
            results = statement.execute_direct(connection, "select * from public.batch_insert_test;", 3);
            show<string>(results);
        }

        // Dates and Times
        statement.execute_direct(connection, "drop table if exists public.date_test;");
        statement.execute_direct(connection, "create table public.date_test (x datetime);");
        statement.execute_direct(connection, "insert into public.date_test values (current_timestamp);");
        results = statement.execute_direct(connection, "select * from public.date_test;");
        results.next();
        nanodbc::date date = results.get<nanodbc::date>(0);
        cout << endl << date.year << "-" << date.month << "-" << date.day << endl;
        results = statement.execute_direct(connection, "select * from public.date_test;");
        show<string>(results);

        // Cleanup
        statement.execute_direct(connection, "drop table if exists public.date_test;");
        statement.execute_direct(connection, "drop table if exists public.example_table;");
        statement.execute_direct(connection, "drop table if exists public.batch_insert_test;");

        // The resources used by connection and statement are cleaned up automatically or
        // you can explicitly call statement.close() and/or connection.disconnect().
    }
    catch(const exception& e)
    {
        cerr << "exception: " << e.what() << endl;
    }
}
```
