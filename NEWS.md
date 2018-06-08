# odbc 1.1.6

## Features

* `dbConnect()` gains a `timeout` parameter, to control how long a connection
  should be attempted before timing out. (#139)

* Full schema support using Id objects available in DBI 8.0 (#91, #120)

## Bugfixes

* SQL inputs are always converted to database encoding before querying (#179).

# odbc 1.1.5

* Fix the return value for `dbQuoteIdentifier()` when given a length 0 input
  (#146 @edgararuiz).

# odbc 1.1.4

* Fix multiple transactions with rollback (#136).

* Add custom `sqlCreateTable` and `dbListTables` method for Taradata connections (@edgararuiz)
## Features

* Add custom `sqlCreateTable` and `dbListTables` method for Teradata
  connections (@edgararuiz)

* Add `dbms.name` parameter to `dbConnect()` to allow the user to set the
  database management system name in cases it cannot be queried from the
  Driver (#115, @hoxo-m).

## Bugfixes

* Fix multiple transactions with rollback (#136).

* Fix translation of missing values for integer types (#119).

* Update PIC flags to avoid portability concerns.

# odbc 1.1.3

* Small patch to fix install errors on CRAN's MacOS machines.

# odbc 1.1.2

* Add `bigint` parameter to `dbConnect()` to allow the user to set the behavior
  when converting 64 bit integers into R types.

* Fixes for compatibility with the RStudio Connections pane and
  viewer. (@jmcphers).

* Define `BUILD_REAL_64_BIT_MODE` for compatibility with older systems `sql.h`,
  to ensure we always use 8 byte pointers.

* Added temporary-table support for Oracle database using a custom
  `sqlCreateTable` (#99, @edgararuiz)

* Fix regression when binding due to the num_columns variable not being updated
  by `odbc_result::bind_list()`.

* Support table creation for Vertica and Redshift (#93, @khotilov).

* Changed parameter `fieldTypes` to `field.types` in functions `dbWriteTable()`
  and `sqlCreateTable()` to be compliant with DBI (#106, @jschelbert).

* dbSendStatement no longer executes the statement, this is instead done when
  `dbBind()` or `dbGetRowsAffected()` is called. This change brings ODBC into
  compliance with the DBI specification for `dbSendStatement()`. (#84, @ruiyiz).

# odbc 1.1.1

* Workaround for drivers which do not implement SQLGetInfo, such as the Access
  driver. (#78)

* Fix for installation error for systems without GNU Make as the default make, such as
  Solaris.

# odbc 1.1.0

* Provide a fall backs for drivers which do not support `SQLDescribeParam` and
  those which do not support transactions.

* `sqlCreateTable()` gains a `fieldTypes` argument, which allows one to
  override a column type for a given table, if the default type is not
  appropriate.

* Support for databases with non UTF-8 encodings. Use the `encoding` parameter
  to `dbConnect()` to specify the database encoding.

* Support for the SQL Connection Pane in the RStudio IDE.

* Unknown fields no longer throw a warning, instead they signal a custom
  condition, which can be caught if desired with

    withCallingHandlers(expr, odbc_unknown_field_type = function(e) {...} )

* Conversion to and from timezones is handled by the
  [cctz](https://github.com/google/cctz) library. If the database is in a non-UTC
  timezone it can be specified with the `timezone` parameter to `dbConnect()`.

* Time objects are converted to and from `hms` objects.

* 64 bit integers are converted to and from `bit64` objects.

* Support table creation for Impala and Hive Databases (# 38, @edgararuiz).

# odbc 1.0.1

* Fixes for the CRAN build machines
  - Do not force c++14 on windows
  - Turn off database tests on CRAN, as I think they will be difficult to debug even if databases are supported.

* Added a `NEWS.md` file to track changes to the package.

# odbc 1.0.0

* Initial odbc release
