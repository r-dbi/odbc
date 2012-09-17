#include "picodbc.h"
#include <iostream>

using namespace std;

template<class T>
void show(picodbc::result results)
{
    cout << "displaying " << results.rows() << " rows:" << endl;

    const short columns = results.columns();

    cout << "row\t";
    for(short i = 0; i < columns; ++i)
        cout << results.column_name(i) << "\t";
    cout << endl;

    long row = 0;
    while(results.next())
    {
        cout << row++ << "\t";
        for(short i = 0; i < columns; ++i)
        {
            if(results.is_null(i))
                cout << "(null)";
            else
                cout << "(" << results.get<T>(i) << ")";
            cout << "\t";
        }
        cout << endl;
    }
}

int main()
{
    const char* connection_string = "a SQLDriverConnect connection string";
    #define EXAMPLE_TABLE "public.example_table"

    try
    {
        // Establishing connections
        picodbc::connection connection(connection_string);
        // or picodbc::connection connection(connection_string, timeout_seconds);
        // or picodbc::connection connection("data source name", "username", "password");
        // or picodbc::connection connection("data source name", "username", "password", timeout_seconds);

        picodbc::statement statement;
        picodbc::result results;

        // Direct execution
        results = statement.execute_direct(connection, "select * from " EXAMPLE_TABLE ";");
        show<string>(results);

        // Binding parameters
        statement.prepare(connection, "select * from " EXAMPLE_TABLE " where cast(a as float) = ?;");
        statement.bind_parameter(0, 1.0);

        results = statement.execute();
        show<string>(results);

        // Transactions
        {
            picodbc::transaction transaction(connection);
            statement.execute_direct(connection, "delete from " EXAMPLE_TABLE " where true;");
            // transaction will be rolled back if we don't call transaction.commit()
        }

        // The resources used by connection and statement are cleaned up automatically or
        // you can explicitly call statement.close() and/or connection.disconnect().
    }
    catch(const exception& e)
    {
        cerr << "exception: " << e.what() << endl;
    }
}