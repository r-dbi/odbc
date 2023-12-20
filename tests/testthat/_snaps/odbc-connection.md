# errors if unnamed arguments

    Code
      build_connection_string(1, 2, 3)
    Condition
      Error in `DBI::dbConnect()`:
      ! All elements of ... must be named.

# errors about case-insensitve arguments

    Code
      build_connection_string(xa = 1, xA = 1)
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA
    Code
      build_connection_string(xa = 1, xA = 1, XA = 1)
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA, XA
    Code
      build_connection_string(xa = 1, xA = 1, xb = 1, xB = 1)
    Condition
      Error in `DBI::dbConnect()`:
      ! After ignoring case, some arguments have the same name:
      * xa, xA
      * xb, xB

