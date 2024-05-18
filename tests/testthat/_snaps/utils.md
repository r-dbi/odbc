# parse_size works

    Code
      parse_size("foo")
    Condition
      Error:
      ! `"foo"` must be a whole number, not the string "foo".

# id_field checks inputs

    Code
      id_field(DBI::Id("a"), "foo")
    Condition
      Error:
      ! `field` must be one of "catalog", "schema", or "table", not "foo".
    Code
      id_field(DBI::Id("a", "b", "c", "d"))
    Condition
      Error:
      ! Identifier must be length 1, 2, or 3.

# errors are rethrown informatively (#643, #788)

    Code
      dbConnect(odbc(), dsn = "does_not_exist_db")
    Condition
      Error in `dbConnect()`:
      ! ODBC failed with error 00000 from [unixODBC][Driver Manager].
      x Data source name not found and no default driver specified
      i From 'nanodbc/nanodbc.cpp:1141'.

---

    Code
      dbExecute(con, "SELECT * FROM boopbopbopbeep")
    Condition
      Error in `dbExecute()`:
      ! ODBC failed with error 00000 from [SQLite].
      x no such table: boopbopbopbeep (1)
      * <SQL> 'SELECT * FROM boopbopbopbeep'
      i From 'nanodbc/nanodbc.cpp:1713'.

# rethrow_database_error() errors well when parse_database_error() fails

    Code
      rethrow_database_error("boop", call = NULL)
    Condition
      Error:
      ! boop

# parse_database_error() works with messages from the wild

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error 00000 from [unixODBC][Driver Manager].
      x  Data source name not found and no default driver specified
      i From 'nanodbc/nanodbc.cpp:1135'.

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error 07002 from [Microsoft][ODBC Driver 17 for SQL Server].
      x  COUNT field incorrect or syntax error
      i From 'nanodbc/nanodbc.cpp:1594'.

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error 07002 from [ODBC Firebird Driver].
      x  COUNT field incorrect
      i From 'nanodbc/nanodbc.cpp:1710'.

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error HYT00 from [Microsoft][SQL Server Native Client 11.0].
      x  Query timeout expired
      i From 'nanodbc/nanodbc.cpp:1655'.

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error 00000 from [Microsoft][ODBC Driver 18 for SQL Server].
      x  Login timeout expired
      *  TCP Provider: Error code 0x2726
      *  A network-related or instance-specific error has occurred while establishing a connection to 127.0.0.1. Server is not found or not accessible. Check if instance name is correct and if SQL Server is configured to allow remote connections. For more information see SQL Server Books Online.
      i From 'nanodbc/nanodbc.cpp:1147'.

# check_row.names()

    Code
      dbWriteTable(con, "boopery", data.frame(bop = 1), row.names = c("no", "way"))
    Condition
      Error in `dbWriteTable()`:
      ! `row.names` must be `NULL`, `TRUE`, `FALSE`, `NA`, or a single string, not a character vector.

# check_field.types()

    Code
      dbWriteTable(con, "boopery", data.frame(bop = 1), field.types = "numeric")
    Condition
      Error in `dbWriteTable()`:
      ! `field.types` must be `NULL` or a named vector of field types, not a string.

# check_attributes()

    Code
      con <- test_con("SQLITE", attributes = list(boop = "bop"))
    Condition
      Error in `dbConnect()`:
      ! `attributes` does not support the connection attribute "boop".
      i Allowed connection attribute is "azure_token".

---

    Code
      con <- test_con("SQLITE", attributes = list(boop = "bop", beep = "boop"))
    Condition
      Error in `dbConnect()`:
      ! `attributes` does not support the connection attributes "boop" and "beep".
      i Allowed connection attribute is "azure_token".

# configure_spark() errors informatively on failure to install unixODBC

    Code
      databricks()
    Condition
      Error in `databricks()`:
      ! Unable to locate the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

# databricks() errors informatively when spark ini isn't writeable

    Code
      write_spark_lines("", ".", ".", call2("databricks"))
    Condition
      Error in `databricks()`:
      ! Detected needed changes to the driver configuration file at ., but the file was not writeable.
      i Please make the changes outlined at https://solutions.posit.co/connections/db/databases/databricks/#troubleshooting-apple-macos-users.

