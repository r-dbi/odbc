# Connect to a database via an ODBC driver

The `dbConnect()` method documented here is invoked when
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) is
called with the first argument `odbc()`. Connecting to a database via an
ODBC driver is likely the first step in analyzing data using the odbc
package; for an overview of package concepts, see the *Overview* section
below.

## Usage

``` r
odbc()

# S4 method for class 'OdbcDriver'
dbConnect(
  drv,
  dsn = NULL,
  ...,
  timezone = "UTC",
  timezone_out = "UTC",
  encoding = "",
  name_encoding = "",
  bigint = c("integer64", "integer", "numeric", "character"),
  timeout = 10,
  driver = NULL,
  server = NULL,
  database = NULL,
  uid = NULL,
  pwd = NULL,
  dbms.name = NULL,
  attributes = NULL,
  interruptible = getOption("odbc.interruptible", interactive()),
  .connection_string = NULL
)
```

## Arguments

- drv:

  An `OdbcDriver`, from `odbc()`.

- dsn:

  The data source name. For currently available options, see the `name`
  column of
  [`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md)
  output.

- ...:

  Additional ODBC keywords. These will be joined with the other
  arguments to form the final connection string.

  Note that ODBC parameter names are case-insensitive so that (e.g.)
  `DRV` and `drv` are equivalent. Since this is different to R and a
  possible source of confusion, odbc will error if you supply multiple
  arguments that have the same name when case is ignored.

  Any values containing a leading or trailing space, a `=`, `;`, `{`, or
  `}` are likely to require quoting. Use
  [`quote_value()`](https://odbc.r-dbi.org/dev/reference/quote_value.md)
  for a fairly standard approach or see your driver documentation for
  specifics.

- timezone:

  The server time zone. Useful if the database has an internal timezone
  that is *not* 'UTC'. If the database is in your local timezone, set
  this argument to
  [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html). See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for a complete
  list of available time zones on your system. Note, if the datatype
  itself carries timezone information, as is the case, for example, with
  SQL Server::DATETIMEOFFSET, `package:odbc` will make an effort to
  respect the timezone declared therein. In those cases, this parameter
  is not used - the timezone that is part of the datatype takes
  precedence.

- timezone_out:

  The time zone returned to R. If you want to display datetime values in
  the local timezone, set to
  [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html).

- encoding:

  The text encoding used on the Database. If the database is not using
  UTF-8 you will need to set the encoding to get accurate re-encoding.
  See [`iconvlist()`](https://rdrr.io/r/base/iconv.html) for a complete
  list of available encodings on your system. Note strings are always
  returned `UTF-8` encoded.

- name_encoding:

  The text encoding for column names used on the Database. May be
  different than the `encoding` argument. Defaults to empty string which
  is equivalent to returning the column names without performing any
  conversion.

- bigint:

  The R type that `SQL_BIGINT` types should be mapped to. Default is
  [bit64::integer64](https://rdrr.io/pkg/bit64/man/bit64-package.html),
  which allows the full range of 64 bit integers.

- timeout:

  Time in seconds to timeout the connection attempt. Setting a timeout
  of `Inf` or `NA` indicates no timeout. Defaults to 10 seconds.

- driver:

  The ODBC driver name or a path to a driver. For currently available
  options, see the `name` column of
  [`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md)
  output.

- server:

  The server hostname. Some drivers use `Servername` as the name for
  this argument. Not required when configured for the supplied `dsn`.

- database:

  The database on the server. Not required when configured for the
  supplied `dsn`.

- uid:

  The user identifier. Some drivers use `username` as the name for this
  argument. Not required when configured for the supplied `dsn`.

- pwd:

  The password. Some drivers use `password` as the name for this
  argument. Not required when configured for the supplied `dsn`.

- dbms.name:

  The database management system name. This should normally be queried
  automatically by the ODBC driver. This name is used as the class name
  for the OdbcConnection object returned from `dbConnect()`. However, if
  the driver does not return a valid value, it can be set manually with
  this parameter.

- attributes:

  A list of connection attributes that are passed prior to the
  connection being established. See
  [ConnectionAttributes](https://odbc.r-dbi.org/dev/reference/ConnectionAttributes.md).

- interruptible:

  Logical. If `TRUE` calls to `SQLExecute` and `SQLExecuteDirect` can be
  interrupted when the user sends SIGINT ( ctrl-c ). Otherwise, they
  block. Defaults to `TRUE` in interactive sessions, and `FALSE`
  otherwise. It can be set explicitly either by manipulating this
  argument, or by setting the global option `odbc.interruptible`.

- .connection_string:

  A complete connection string, useful if you are copy pasting it from
  another source. If this argument is used, any additional arguments
  will be appended to this string.

## Connection strings

Internally, `dbConnect()` creates a connection string using the supplied
arguments. Connection string keywords are driver-dependent; the
arguments documented here are common, but some drivers may not accept
them.

Alternatively to configuring DSNs and driver names with the driver
manager, you can pass a complete connection string directly as the
`.connection_string` argument. [The Connection Strings
Reference](https://www.connectionstrings.com) is a useful resource that
has example connection strings for a large variety of databases.

## Overview

The odbc package is one piece of the R interface to databases with
support for ODBC:

![](figures/whole-game.png)

The package supports any **Database Management System (DBMS)** with ODBC
support. Support for a given DBMS is provided by an **ODBC driver**,
which defines how to interact with that DBMS using the standardized
syntax of ODBC and SQL. Drivers can be downloaded from the DBMS vendor
or, if you're a Posit customer, using the [professional
drivers](https://docs.posit.co/pro-drivers/). To manage information
about each driver and the data sources they provide access to, our
computers use a **driver manager**. Windows is bundled with a driver
manager, while MacOS and Linux require installation of one; this package
supports the [unixODBC](https://www.unixodbc.org/) driver manager.

In the **R interface**, the [DBI package](https://dbi.r-dbi.org/)
provides a front-end while odbc implements a back-end to communicate
with the driver manager. The odbc package is built on top of the
[nanodbc](https://nanodbc.github.io/nanodbc/) C++ library.

Interfacing with DBMSs using R and odbc involves three high-level steps:

1.  *Configure drivers and data sources*: the functions
    [`odbcListDrivers()`](https://odbc.r-dbi.org/dev/reference/odbcListDrivers.md),
    [`odbcListDataSources()`](https://odbc.r-dbi.org/dev/reference/odbcListDataSources.md),
    and
    [`odbcListConfig()`](https://odbc.r-dbi.org/dev/reference/odbcListConfig.md)
    help to interface with the driver manager.

2.  *Connect to a database*: The `dbConnect()` function, called with the
    first argument odbc(), connects to a database using the specified
    ODBC driver to create a connection object.

3.  *Interface with connections*: The resulting connection object can be
    passed to various functions to retrieve information on database
    structure (\[DBI::dbListTables()\]\[\]), iteratively develop queries
    ([`DBI::dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html),
    [`DBI::dbColumnInfo()`](https://dbi.r-dbi.org/reference/dbColumnInfo.html)),
    and query data objects
    ([`DBI::dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html)).

## Learn more

To learn more about databases:

- ["Best Practices in Working with
  Databases"](https://solutions.posit.co/connections/db/) documents how
  to use the odbc package with various popular databases.

- [The pyodbc "Drivers and Driver Managers"
  Wiki](https://github.com/mkleehammer/pyodbc/wiki/Drivers-and-Driver-Managers)
  provides further context on drivers and driver managers.

- [Microsoft's "Introduction to
  ODBC"](https://learn.microsoft.com/en-us/sql/odbc/reference) is a
  thorough resource on the ODBC interface.
