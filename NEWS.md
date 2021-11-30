# odbc (development version)

# odbc 1.3.3

* Hadley Wickham is now the maintainer.

# odbc 1.3.2

* New `odbcDataType.Snowflake()` method for Snowflake databases. (@edgararuiz, #451)

# odbc 1.3.1

* Fixed warnings about anonymous unions (@detule, #440)
* Fixed `invalid descriptor` issues when retrieving results from SQL Server +
  Microsoft's ODBC driver, using parametrized queries. (@detule, #414)
* Fixed null handling in SQL Server / Azure result sets retrieved with
  Microsoft's ODBC driver. (@detule, #408)
* Hive uses C-style escaping for string literals (single quotes are
  backslash-escaped, note single quote-escaped). `dbQuoteString` now respects
  this when called on a connection of class `Hive`. (@rnorberg, #184)
* When calling `sqlCreateTable(con, ..., temporary = TRUE)` and `con` is a
  connection of class `DB2/AIX64`, the `CREATE TABLE` statement that is generated
  properly creates a temporary table in DB2. The statement begins with
  [`DECLARE GLOBAL TEMPORARY TABLE`](https://www.ibm.com/docs/SSEPEK_11.0.0/sqlref/src/tpc/db2z_sql_declareglobaltemptable.html)
  and ends with `ON COMMIT PRESERVE ROWS` (DB2's default behavior is
  `ON COMMIT DELETE ROWS`, which results in the inserted data being
  deleted as soon as `dbWriteTable` completes). (@rnorberg, #426)
* Fixed RStudio Connections Pane when working with a database that has only one catalog or one schema. (@meztez, #444)

# odbc 1.3.0

## Major changes
* odbc can now be compiled again with Rtools35 (gcc 4.9.3) on Windows (#383)
* `invalid descriptor` errors from drivers such as Microsoft SQLServer driver and the freeTDS driver which do not support out of order retrieval are now avoided.
  This is done by unbinding any nanodbc buffer past the long column.
  Performance for the unbound columns in these cases will be reduced, but the retrieval will work without error (@detule, #381)
* `dbBind()` and `dbFetch()` now support multiple result sets (@vkapartzianis, #345)

## Minor improvements and fixes
* New `dbAppendTable()` method for OdbcConnection objects (#335)
* `dbQuoteIdentifier()` now uses the input names (if any).
* `dbWriteTable()` and `dbBind()` now default to a `batch_rows` of `NA`, which sets the batch size to be the length of the input.
  This avoids problems with drivers that don't support batch sizes larger than the input size.
  To restore the behavior prior to this release pass `batch_rows = 1024` or set `options(odbc.batch_rows = 1024)` (#391).
* `dbWriteTable()` now handles `data.table::IDate()` objects (#388)
* `dbWriteTable(field.types=)` now issues a warning rather than an error for missing columns (#342)
* `odbcConnectionColumns()` now works as intended with `DBI::Id()` objects (#389)
* `dbFetch()` now verifies that `n` is a valid input.
* Dates are now always interpreted as being in the database's local time zone, regardless of the `timezone` parameter (#398)
* Oracle connections now support `Date` and `POSIXct` types via `DATE` and `TIMESTAMP` data types (#324, #349, #350)
* Oracle connections now use VARCHAR2 rather than VARCHAR, as recommended by Oracle's documentation (#189)

# odbc 1.2.3

* `dbWriteTable()` now executes immediately, which fixes issues with temporary tables and the FreeTDS SQL Server driver (@krlmlr).

* blob roundtrips now work in more cases (#364, @krlmlr).

* The BH dependency has been removed (#326)

# odbc 1.2.2

* The configure script now again uses iodbc-config on macOS, if available.

* Fix errors with drivers who do not fully implement SQLGetInfo (#325).

# odbc 1.2.1

* Fix the unicode character width issues with the macOS odbc CRAN binary. (#283)

* The configure script now works on systems whose /bin/sh does not support
  command substitution, such as Solaris 10.

# odbc 1.2.0

## Features

* `sqlCreateTable()` and `dbWriteTable()` now throw an error if you mistakenly
  include `field.types` names which do not exist in the input data. (#271)

* The error message when trying to write tables with unsupported types now
  includes the column name (#238).

* `dbConnect()` now has a new param `timezone_out` which is useful if the user
  wants the datetime values be marked with a specific timezone instead of UTC
  (@shrektan, #294).

* `dbGetQuery()`, `dbSendQuery()` and `dbSendStatement()` gain a `immediate`
  argument to execute the statement or query immediately instead of preparing,
  then executing the statement. (#272, @krlmlr)

* `dbGetQuery()`, `dbSendQuery()` and `dbSendStatement()` gain a `params`
  argument, which allows them to be used (indirectly) by `DBI::dbAppendTable()`
  (#210, #215, #261).

* `dbWriteTable()` and `dbBind()` methods gain a `batch_rows` argument, to
  control how many rows are bound in each batch. The default can be set
  globally with `options(odbc.batch_rows)`. This is useful if your database
  performs better with a larger or smaller number of rows per batch than the
  default of 1024. (#297)

* New `odbcConnectionColumns()` function to describe the column types. This
  data is used when binding columns, which allows drivers which do not support
  the `SQLDescribeParam()` ODBC function, such as freeTDS to work better with
  bound columns. (#313, @detule)

* Added a Teradata `odbcDataType()` to support writing logical data to Teradata
  servers (#240, @blarj09).

* Added a Access `odbcDataType()` method to support writing to Access databases
  (#262, @vh-d)

* `odbcListDrivers()` gains a `keep` and `filter` argument and global options
  `odbc.drivers_keep`, `odbc.drivers_filter` to keep and filter the drivers
  returned. This is useful if system administrators want to reduce the number
  of drivers shown to users. (@blairj09, #274)

* Subseconds are now retained when inserting POSIXct objects (#130, #208)

* The RStudio Connections Pane now shows the DSN, when available (#304,
  @davidchall).

## Bugfixes

* SQL Server ODBC's now supports the '-155' data type, and its losing
  sub-second precision on timestamps; this still returns type `DATETIMEOFFSET`
  as a character, but it preserves sub-seconds and has a numeric timezone
  offset (@r2evans, #207).

* `dbExistsTable()` now handles the case-sensitivity consistently as
  other methods (@shrektan, #285).

* `dbExistsTable()` now works for SQL Server when specifying schemas but not
  catalogs using the freeTDS and Simba drivers. (#197)

* `DBI::dbListFields()` no longer fails when used with a
  a qualified Id object (using both schema and table) (#226).

* `dbWriteTable()` now always writes `NA_character` as `NULL` for
  data.frame with only one row (@shrektan, #288).

* Fix an issue that the date value fetched from the database may be one
  day before its real value (@shrektan, #295).

# odbc 1.1.6

## Features

* `dbConnect()` gains a `timeout` parameter, to control how long a connection
  should be attempted before timing out (#139).

* Full schema support using Id objects available in DBI 0.8 (#91, #120).

## Bugfixes

* SQL inputs are always converted to database encoding before querying (#179).

# odbc 1.1.5

* Fix the return value for `dbQuoteIdentifier()` when given a length 0 input
  (#146 @edgararuiz).

# odbc 1.1.4

## Features

* Add custom `sqlCreateTable` and `dbListTables` method for Teradata
  connections (#121, @edgararuiz).

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
  `sqlCreateTable` (#99, @edgararuiz).

* Fix regression when binding due to the num_columns variable not being updated
  by `odbc_result::bind_list()`.

* Support table creation for Vertica and Redshift (#93, @khotilov).

* Changed parameter `fieldTypes` to `field.types` in functions `dbWriteTable()`
  and `sqlCreateTable()` to be compliant with DBI (#106, @jschelbert).

* dbSendStatement no longer executes the statement, this is instead done when
  `dbBind()` or `dbGetRowsAffected()` is called. This change brings ODBC into
  compliance with the DBI specification for `dbSendStatement()` (#84, @ruiyiz).

# odbc 1.1.1

* Workaround for drivers which do not implement SQLGetInfo, such as the Access
  driver (#78).

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

* Support table creation for Impala and Hive Databases (#38, @edgararuiz).

# odbc 1.0.1

* Fixes for the CRAN build machines
  - Do not force c++14 on windows
  - Turn off database tests on CRAN, as I think they will be difficult 
    to debug even if databases are supported.

* Added a `NEWS.md` file to track changes to the package.

# odbc 1.0.0

* Initial odbc release
