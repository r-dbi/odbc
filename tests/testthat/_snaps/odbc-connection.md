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

# warns if your values might need quoting

    Code
      build_connection_string(foo = "f{o")
    Condition
      Warning:
      `foo` contains a special character that may need quoting.
      i If the connection worked, you don't need to quote it and you can use `I()` to suppress this warning.
      i Otherwise, wrap the value in `odbc::quote_value()` to use a heuristic that should work for most backends.
      i If that still doesn't work, consult your driver's documentation.
    Output
      [1] "foo=f{o"

# automatically picks correct quote type

    Code
      quote_value("'\"")
    Condition
      Error in `quote_value()`:
      ! Don't know how to escape a value with both single and double quotes.

