# odbcListConfig errors informatively without unixODBC

    Code
      odbcListConfig()
    Condition
      Error in `odbcListConfig()`:
      ! The unixODBC driver manager is not available. 
      * Please install and try again.

# odbcListConfig errors informatively with unexpected odbcinst output

    Code
      odbcListConfig()
    Condition
      Error in `odbcListConfig()`:
      ! Failed to parse output from odbcinst.
      i This is an internal error that was detected in the odbc package.
        Please report it at <https://github.com/r-dbi/odbc/issues> with a reprex (<https://tidyverse.org/help/>) and the full backtrace.

---

    Code
      odbcListConfig()
    Condition
      Error in `odbcListConfig()`:
      ! Failed to parse output from odbcinst.
      i This is an internal error that was detected in the odbc package.
        Please report it at <https://github.com/r-dbi/odbc/issues> with a reprex (<https://tidyverse.org/help/>) and the full backtrace.

# odbcEdit*() errors informatively on Windows

    Code
      odbcEditDrivers()
    Condition
      Error in `odbcEditDrivers()`:
      ! Configuration files are only available on macOS and Linux.
      i Use the ODBC Data Source Administrator to configure connections on Windows.

