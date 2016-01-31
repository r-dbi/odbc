#include "nanodbc.h"
#include "example_unicode_utils.h"

#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;
using namespace nanodbc;

int main()
{
    try
    {
        connection conn(NANODBC_TEXT("NorthWind"));
        result row = execute(conn, NANODBC_TEXT(
            "SELECT CustomerID, ContactName, Phone"
            "   FROM CUSTOMERS"
            "   ORDER BY 2, 1, 3"));

        for (int i = 1; row.next(); ++i)
        {
            cout << i << " :"
                << convert(row.get<string_type>(0)) << " "
                << convert(row.get<string_type>(1)) << " "
                << convert(row.get<string_type>(2)) << " "
                << endl;
        }
    }
    catch (runtime_error const& e)
    {
        cerr << e.what() << endl;
    }
}
