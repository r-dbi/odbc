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
