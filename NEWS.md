# odbc (development version)

## Features

* Added a Access `odbcDataType()` method to support writing to Access databases
  (#262, @vh-d)

* `dbGetQuery()`, `dbSendQuery()` and `dbSendStatement()` gain a `immediate`
  argument to execute the statement or query immediately instead of preparing,
  then executing the statement. (#272, @krlmlr)

* `dbWriteTable()` and `dbBind()` methods gain a `batch_rows` argument, to
  control how many rows are bound in each batch. The default can be set
  globally with `options(odbc.batch_rows)`. This is useful if your database
  performs better with a larger or smaller number of rows per batch than the
  default of 1024. (#297)

* New `odbcConnectionColumns()` function to describe the column types. This
  data is used when binding columns, which allows drivers which do not support
  the `SQLDescribeParam()` ODBC function, such as freeTDS. (#313, @detule)

* Added a Teradata `odbcDataType()` to support writing logical data to Teradata servers (#240, @blarj09).

* Subseconds are now retained when inserting POSIXct objects (#130, #208)

* `dbGetQuery()`, `dbSendQuery()` and `dbSendStatement()` gain a `params` argument, which allows them to be
  used (indirectly) by `DBI::dbAppendTable()` (#210, #215, #261).

* `odbcListDrivers()` gains a `keep` and `filter` argument and global options
  `odbc.drivers_keep`, `odbc.drivers_filter` to keep and filter the drivers
  returned. This is useful if system administrators want to reduce the number
  of drivers shown to users. (@blairj09, #274)

* The RStudio Connections Pane now shows the DSN, when available (#304, @davidchall).

* `dbConnect()` now has a new param `timezone_out` which is useful if the user wants 
  the datetime values be marked with a specific timezone instead of UTC (@shrektan, #294).

## Bugfixes

* Fixed an issue where `DBI::dbListFields()` could fail when used with a
  a qualified Id object (using both schema and table) (#226).

* Fix SQL Server ODBC's unsupported '-155' data type, and its losing
* `dbExistsTable()` now works for SQL Server when specifying schemas but not
  catalogs using the freeTDS and Simba drivers. (#197)

- fix SQL Server ODBC's unsupported '-155' data type, and its losing
  sub-second precision on timestamps; this still returns type
  `DATETIMEOFFSET` as a character, but it preserves sub-seconds and
  has a numeric timezone offset (@r2evans, #207).
  
* Fix an issue that the date value fetched from the database may be one
  day before its real value (@shrektan, #295).

* `dbExistsTable()` now handles the case-sensitivity consistently as
  other methods (@shrektan, #285).

* `dbWriteTable()` now always writes `NA_character` as `NULL` for
  data.frame with only one row (@shrektan, #288).

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
