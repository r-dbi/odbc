# errors if unnamed arguments

    Code
      check_args(list(1, 2, 3))
    Condition
      Error in `DBI::dbConnect()`:
      ! All elements of ... must be named.

# errors about case-insensitve arguments

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

# messages if values might need quoting

    Code
      check_quoting(list(foo = "f{oo", bar = "b{ar", baz = "baz"))
    Message
      `foo`, `bar` contains a special character that may need quoting.
      i Wrap the value in `odbc::quote_value()` to use a heuristic that should work for most drivers.
      i If that still doesn't work, consult your driver's documentation.
      i Otherwise, you can suppress this message by wrapping the value in `I()`.

# automatically picks correct quote type

    Code
      quote_value("'\"")
    Condition
      Error in `quote_value()`:
      ! Don't know how to escape a value with both single and double quotes.

# validateObjectName() errors informatively

    Code
      odbcListColumns(con, table = "boop", view = "bop")
    Condition
      Error in `odbcListColumns()`:
      ! Exactly one of `table` or `view` must be supplied.

---

    Code
      odbcListColumns(con)
    Condition
      Error in `odbcListColumns()`:
      ! One of `table` or `view` must be supplied.

