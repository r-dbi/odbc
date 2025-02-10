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
      i See `?odbc::odbcListDataSources()` to learn more.
      i From 'nanodbc/nanodbc.cpp:1150'.

---

    Code
      dbExecute(con, "SELECT * FROM boopbopbopbeep")
    Condition
      Error in `dbExecute()`:
      ! ODBC failed with error 00000 from [SQLite].
      x no such table: boopbopbopbeep (1)
      * <SQL> 'SELECT * FROM boopbopbopbeep'
      i From 'nanodbc/nanodbc.cpp:1726'.

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
      i See `?odbc::odbcListDataSources()` to learn more.
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

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! ODBC failed with error S1000 from [SAP AG][LIBODBCHDB DLL][HDBODBC][SAP AG][LIBODBCHDB SO][HDBODBC][89013].
      x  General error;403 internal error: Error opening the cursor for the remote database <***.***> Connection not open;-10807 Connection down: Socket closed by peer {***.**.*.**:***** -> ***.**.***.**:***** TenantName:(none) SiteVolumeID:1:3 SiteType:PRIMARY ConnectionID:****** SessionID:************}
      *  <SQL> 'SELECT DISTINCT "po_id", ***CENSORED***'
      i From 'nanodbc/nanodbc.cpp:1722'.

---

    Code
      rethrow_database_error(msg, call = NULL)
    Condition
      Error:
      ! `parse_database_error()` will not {be able to parse this}, but it should still be successfully rethrown as-is.

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

# configure_simba() errors informatively on failure to install unixODBC

    Code
      configure_simba()
    Condition
      Error:
      ! Unable to locate the unixODBC driver manager.
      i Please install unixODBC using Homebrew with `brew install unixodbc`.

# databricks() errors informatively when spark ini isn't writeable

    Code
      write_simba_lines("", ".", ".", call2("databricks"))
    Condition
      Error in `databricks()`:
      ! Detected needed changes to the driver configuration file at ., but the file was not writeable.
      i Please make the changes outlined at https://solutions.posit.co/connections/db/databases/databricks/#troubleshooting-apple-macos-users.

# configure_unixodbc_simba() writes reasonable entries

    Code
      configure_unixodbc_simba(unixodbc_install = unixodbc_install_path,
        simba_config = spark_config_path, action = "warn")
    Condition
      Warning:
      i Detected potentially unsafe driver settings:
      * Please consider revising the `ODBCInstLib` field in 'simba.sparkodbc.ini' and setting its value to "libodbcinst.dylib"
      * Please consider revising the `DriverManagerEncoding` field in 'simba.sparkodbc.ini' and setting its value to "UTF-16".

---

    Code
      configure_unixodbc_simba(unixodbc_install = unixodbc_install_path,
        simba_config = spark_config_path, action = "warn")
    Condition
      Warning:
      i Detected potentially unsafe driver settings:
      * Please consider revising the `ODBCInstLib` field in 'simba.sparkodbc.ini' and setting its value to "libodbcinst.dylib"
      * Please consider revising the `DriverManagerEncoding` field in 'simba.sparkodbc.ini' and setting its value to "UTF-16".

---

    Code
      configure_unixodbc_simba(unixodbc_install = unixodbc_install_path,
        simba_config = spark_config_path, action = "warn")
    Condition
      Warning:
      i Detected potentially unsafe driver settings:
      * Please consider revising the `DriverManagerEncoding` field in 'simba.sparkodbc.ini' and setting its value to "UTF-16".

---

    Code
      configure_unixodbc_simba(unixodbc_install = unixodbc_install_path,
        simba_config = spark_config_path, action = "warn")
    Condition
      Warning:
      i Detected potentially unsafe driver settings:
      * Please consider revising the `ODBCInstLib` field in 'simba.sparkodbc.ini' and setting its value to "libodbcinst.dylib"
      * Please consider revising the `DriverManagerEncoding` field in 'simba.sparkodbc.ini' and setting its value to "UTF-16".

