#include "nanodbc.h"
#include <iostream>
#include <vector>

using namespace std;

template<class T>
void show(nanodbc::result results)
{
    const short columns = results.columns();
    long rows_displayed = 0;

    cout << "\nDisplaying " << results.affected_rows() << " rows (" << results.rowset_size() << " at a time):" << endl;

    cout << "row\t";
    for(short i = 0; i < columns; ++i)
        cout << results.column_name(i) << "\t";
    cout << endl;

    while(results.next())
    {
        const unsigned long rows = results.rows();
        for(unsigned long row = 0; row < rows; ++row)
        {
            cout << rows_displayed++ << "\t";
            for(short col = 0; col < columns; ++col)
            {
                if(results.is_null(col, row))
                    cout << "(null)";
                else
                    cout << "(" << results.get<T>(col, row) << ")";
                cout << "\t";
            }
            cout << endl;
        }
    }
}

int main()
{
    const char* connection_string = "A Data Source Connection String";
    #define EXAMPLE_TABLE "public.example_table"

    try
    {
        // Establishing connections
        nanodbc::connection connection(connection_string);
        // or nanodbc::connection connection(connection_string, timeout_seconds);
        // or nanodbc::connection connection("data source name", "username", "password");
        // or nanodbc::connection connection("data source name", "username", "password", timeout_seconds);
        cout << "Connected with driver " << connection.driver_name() << endl;

        nanodbc::statement statement;
        nanodbc::result results;

        // Direct execution
        results = statement.execute_direct(connection, "select * from " EXAMPLE_TABLE ";");
        show<string>(results);

        // Direct execution, bulk fetching 2 rows at a time
        results = statement.execute_direct(connection, "select * from " EXAMPLE_TABLE ";", 2);
        show<string>(results);

        // Binding parameters
        statement.prepare(connection, "select cast(a as float) as f from " EXAMPLE_TABLE " where cast(a as float) = ?;");
        statement.bind_parameter(0, 1.0);

        results = statement.execute();
        show<double>(results);

        // Transactions
        {
            nanodbc::transaction transaction(connection);
            statement.execute_direct(connection, "delete from " EXAMPLE_TABLE ";");
            // transaction will be rolled back if we don't call transaction.commit()
        }

        // Batch inserting
        {
            statement.execute_direct(connection, "drop table if exists public.batch_insert_test;");
            statement.execute_direct(connection, "create table public.batch_insert_test (x varchar(50), y int);");

            statement.prepare(connection, "insert into public.batch_insert_test values (?, ?);");

            const size_t data_count = 4;

            vector<string> xdata;
            xdata.push_back("this");
            xdata.push_back("is");
            xdata.push_back("a");
            xdata.push_back("test");
            statement.bind_parameter(0, xdata.begin(), xdata.end());

            int ydata[data_count] = { 1, 2, 3, 4 };
            statement.bind_parameter(1, ydata, ydata + data_count);

            nanodbc::transaction transaction(connection);
            statement.execute(data_count);
            transaction.commit();
 
            results = statement.execute_direct(connection, "select * from public.batch_insert_test;");
            show<string>(results);
       }

        // The resources used by connection and statement are cleaned up automatically or
        // you can explicitly call statement.close() and/or connection.disconnect().
    }
    catch(const exception& e)
    {
        cerr << "exception: " << e.what() << endl;
    }
}