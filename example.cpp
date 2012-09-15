#include "picodbc.h"
#include <iostream>

using namespace std;

template<class T>
void show(picodbc::statement& statement)
{
	long row = 0;
	cout << "row\t";
	for(long i = 0; i < statement.columns(); ++i)
		cout << statement.column_name(i) << "\t";
	cout << endl;
	while(statement.next())
	{
		cout << row++ << "\t";
		for(long i = 0; i < statement.columns(); ++i)
		{
			if(statement.is_null(i))
				cout << "null";
			else
				cout << statement.get<T>(i);
			cout << "\t";
		}
		cout << endl;
	}
}

int main()
{
	try
	{
		// Establishing connections
		picodbc::connection connection("data source name", "username", "password");
		// or picodbc::connection connection("a SQLDriverConnect connection string");
		// or picodbc::connection connection("data source name", "username", "password", timeout_seconds);

		picodbc::statement statement;

		// Direct execution
		statement.execute_direct(connection, "select * from public.example_table;");
		show<string>(statement);

		// Binding parameters
		statement.prepare(connection, "select * from public.example_table where cast(col as float) = ?;");
		statement.execute();
		statement.bind_param(0, 1.0);
		show(statement);

		// Transactions
		{
			picodbc::transaction transaction(connection);
			statement.execute_direct(connection, "delete from public.example_table where true;");
			// transaction will be rolled back if we don't call transaction.commit()
		}

		// Preparing statements and manually binding columns
		statement.prepare(connection, "select some_int, some_string from public.example_table;")
		statement.execute()
		int some_int;
		char some_string[512];
		statement.bind_column(0, some_int);
		statement.bind_column(1, some_string, sizeof(some_string));
		while(statement.next())
			cout << some_int << "\t" << some_string << endl;

		// The resources used by connection and statement are cleaned up automatically or
		// you can explicitly call statement.close() and/or connection.disconnect().
	}
	catch(const exception& e)
	{
		cerr << "exception: " << e.what() << endl;
	}
}