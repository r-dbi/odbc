#include "nanodbc.h"
#include <iostream>
#include <vector>

using namespace std;

template<class T>
void show(nanodbc::result results)
{
    const short columns = results.columns();
    long rows_displayed = 0;

    cout << "\nDisplaying " << results.affected_rows() << " rows (" << results.rowset_size() << " fetched at a time):" << endl;

    cout << "row\t";
    for(short i = 0; i < columns; ++i)
        cout << results.column_name(i) << "\t";
    cout << endl;

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

nanodbc::result direct_execution(nanodbc::connection& connection, const string& query)
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

        nanodbc::result results;
        nanodbc::statement statement;

        // Direct execution
        direct_execution(connection, "drop table if exists public.example_table;");
        direct_execution(connection, "create table public.example_table (a int, b varchar(10));");
        direct_execution(connection, "insert into public.example_table values (1, 'one');");
        direct_execution(connection, "insert into public.example_table values (2, 'two');");
        direct_execution(connection, "insert into public.example_table values (3, 'tri');");
        direct_execution(connection, "insert into public.example_table (b) values ('z');");
        results = direct_execution(connection, "select * from public.example_table;");
        show<string>(results);

        // Direct execution, bulk fetching 2 rows at a time
        results = statement.execute_direct(connection, "select * from public.example_table;", 2);
        show<string>(results);

        // Binding parameters
        statement.prepare(connection, "select cast(a as float) as f from public.example_table where cast(a as float) = ?;");
        statement.bind_parameter(0, 1.0);

        results = statement.execute();
        show<double>(results);

        // Transactions
        {
            cout << "\ndeleting all rows ... " << flush;
            nanodbc::transaction transaction(connection);
            statement.execute_direct(connection, "delete from public.example_table;");
            // transaction will be rolled back if we don't call transaction.commit()
        }
        results = direct_execution(connection, "select count(1) from public.example_table;");
        results.next();
        cout << "still have " << results.get<int>(0) << " rows!" << endl;

        // Batch inserting
        {
            statement.execute_direct(connection, "drop table if exists public.batch_insert_test;");
            statement.execute_direct(connection, "create table public.batch_insert_test (x varchar(50), y int, z float);");

            statement.prepare(connection, "insert into public.batch_insert_test (x, y, z) values (?, ?, ?);");

            const size_t data_count = 4;

            vector<string> xdata;
            xdata.push_back("this");
            xdata.push_back("is");
            xdata.push_back("a");
            xdata.push_back("test");
            statement.bind_parameter(0, xdata.begin(), xdata.end());

            int ydata[data_count] = { 1, 2, 3, 4 };
            statement.bind_parameter(1, ydata, ydata + data_count);

            float zdata[data_count] = { 1.1, 2.2, 3.3, 4.4 };
            statement.bind_parameter(2, zdata, zdata + data_count);

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