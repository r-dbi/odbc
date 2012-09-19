#include "picodbc.h"
#include <iostream>

using namespace std;

template<class T>
void show(picodbc::result results)
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
        picodbc::connection connection(connection_string);
        // or picodbc::connection connection(connection_string, timeout_seconds);
        // or picodbc::connection connection("data source name", "username", "password");
        // or picodbc::connection connection("data source name", "username", "password", timeout_seconds);
        cout << "Connected with driver " << connection.driver_name() << endl;

        picodbc::statement statement;
        picodbc::result results;

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
            picodbc::transaction transaction(connection);
            statement.execute_direct(connection, "delete from " EXAMPLE_TABLE ";");
            // transaction will be rolled back if we don't call transaction.commit()
        }

        // Batch inserting
        {
            statement.execute_direct(connection, "drop table if exists public.batch_insert_test;");
            statement.execute_direct(connection, "create table public.batch_insert_test (x int);");

            statement.prepare(connection, "insert into public.batch_insert_test values (?);");

            const size_t data_count = 10000;
            int data[data_count] = { 0 };
            statement.bind_parameter(0, data, data + data_count);

            picodbc::transaction transaction(connection);
            statement.execute(data_count);
            transaction.commit();
        }

        // The resources used by connection and statement are cleaned up automatically or
        // you can explicitly call statement.close() and/or connection.disconnect().
    }
    catch(const exception& e)
    {
        cerr << "exception: " << e.what() << endl;
    }
}