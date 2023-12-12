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

