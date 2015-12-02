#include <stdexcept>
#include <iostream>
#include <string>
#include "nanodbc.h"

#ifndef NANODBC_TEXT
#ifdef NANODBC_USE_UNICODE
#define NANODBC_TEXT(s) L ## s
#else
#define NANODBC_TEXT(s) s
#endif
#endif

#ifdef NANODBC_USE_UNICODE
auto& console = std::wcout;
#else
auto& console = std::cout;
#endif

int main()
{
    try
    {
        nanodbc::connection conn(NANODBC_TEXT("NorthWind"));
        nanodbc::result row = execute(conn, NANODBC_TEXT(
            "SELECT CustomerID, ContactName, Phone"
            "   FROM CUSTOMERS"
            "   ORDER BY 2, 1, 3"));

        for (int i = 1; row.next(); ++i)
        {
            console
                << i << NANODBC_TEXT(" :")
                << row.get<nanodbc::string_type>(0) << NANODBC_TEXT(" ")
                << row.get<nanodbc::string_type>(1) << NANODBC_TEXT(" ")
                << row.get<nanodbc::string_type>(2) << NANODBC_TEXT(" ")
                << std::endl;
        }
    }
    catch (std::runtime_error const& e)
    {
        std::cerr << e.what() << std::endl;
    }
}
