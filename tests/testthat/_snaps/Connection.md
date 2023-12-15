# warn about case-insensitve arguments

    Code
      check_args(list(xa = 1, xA = 1))
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA
    Code
      check_args(list(xa = 1, xA = 1, XA = 1))
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA, XA
    Code
      check_args(list(xa = 1, xA = 1, xb = 1, xB = 1))
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA
      * xb, xB

# odbcListConfig errors informatively without unixODBC (mocked)

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

