
<!-- README.md is generated from README.Rmd. Please edit that file -->

# odbc

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/odbc)](https://cran.r-project.org/package=odbc)
[![R build
status](https://github.com/r-dbi/odbc/workflows/R-CMD-check/badge.svg)](https://github.com/r-dbi/odbc/actions?workflow=R-CMD-check)
[![Coverage
Status](https://img.shields.io/codecov/c/github/r-dbi/odbc/master.svg)](https://codecov.io/github/r-dbi/odbc?branch=master)
<!-- badges: end -->

The goal of the odbc package is to provide a DBI-compliant interface to
[Open Database
Connectivity](https://msdn.microsoft.com/en-us/library/ms710252\(v=vs.85\).aspx)
(ODBC) drivers. This allows for an efficient, easy to setup connection
to any database with ODBC drivers available, including [SQL
Server](https://www.microsoft.com/en-us/sql-server/),
[Oracle](https://www.oracle.com/database),
[MySQL](https://www.mysql.com/),
[PostgreSQL](https://www.postgresql.org/), [SQLite](https://sqlite.org/)
and others. The implementation builds on the
[nanodbc](https://nanodbc.github.io/nanodbc/) C++ library.

  - [Installation](#installation)
      - [Windows](#windows)
      - [MacOS](#macos)
      - [Linux - Debian / Ubuntu](#linux---debian-ubuntu)
      - [R](#r)
  - [Connecting to a Database](#connecting-to-a-database)
      - [Connection Strings](#connection-strings)
      - [DSN Configuration files](#dsn-configuration-files)
  - [Usage](#usage)
      - [Table and Field information](#table-and-field-information)
      - [Reading](#reading)
      - [Writing](#writing)
      - [Querying](#querying)
  - [Benchmarks](#benchmarks)
      - [Reading](#reading-1)
      - [Writing](#writing-1)

## Installation

For Unix and MacOS ODBC drivers should be compiled against
[unixODBC](http://www.unixodbc.org/). Drivers compiled against
[iODBC](http://www.iodbc.org/) *may* also work, but are not fully
supported.

After installation of the driver manager and driver, you will have to
register the driver in a [odbcinst.ini](#dsn-configuration-files) file
for it to appear in `odbc::odbcListDrivers()`.

**odbc** and it’s dependencies use C++11 features. Therefore you need
[gcc 4.8](https://gcc.gnu.org/), [clang 3.3](https://clang.llvm.org) or
[Rtools 3.3](https://CRAN.R-project.org/bin/windows/Rtools/) or later.

### Windows

Windows is bundled with ODBC libraries however drivers for each database
need to be installed separately. Windows ODBC drivers typically include
an installer that needs to be run and will install the driver to the
proper locations.

### MacOS

[homebrew](http://brew.sh/) can be used to easily install database
drivers on MacOS.

#### UnixODBC - Required for all databases

``` shell
# Install the unixODBC library
brew install unixodbc
```

#### Common DB drivers

``` shell
# Microsoft SQL Server ODBC Drivers (Recommended)
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install msodbcsql17 mssql-tools

# SQL Server ODBC Drivers (Free TDS)
brew install freetds --with-unixodbc

# PostgreSQL ODBC ODBC Drivers
brew install psqlodbc

# MySQL ODBC Drivers (and database)
brew install mysql

# SQLite ODBC Drivers
brew install sqliteodbc
```

### Linux - Debian / Ubuntu

[apt-get](https://wiki.debian.org/Apt) can be used to easily install
database drivers on Linux distributions which support it, such as Debian
and Ubuntu.

#### UnixODBC - Required for all databases

``` shell
# Install the unixODBC library
apt-get install unixodbc unixodbc-dev
```

#### Common DB drivers

For SQL Server on Linux it is recommended you use the [Microsoft
Drivers](https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#ubuntu).

``` shell
# SQL Server ODBC Drivers (Free TDS)
apt-get install tdsodbc

# PostgreSQL ODBC ODBC Drivers
apt-get install odbc-postgresql

# MySQL ODBC Drivers
apt-get install libmyodbc

# SQLite ODBC Drivers
apt-get install libsqliteodbc
```

### R

``` r
# Install the latest odbc release from CRAN:
install.packages("odbc")

# Or the the development version from GitHub:
# install.packages(devtools)
devtools::install_github("r-dbi/odbc")
```

## Connecting to a Database

Databases can be connected by specifying a connection string directly,
or with DSN configuration files.

### Connection Strings

Specify a connection string as named arguments directly in the
`dbConnect()` method.

``` r
library(DBI)
con <- dbConnect(odbc::odbc(),
  driver = "PostgreSQL Driver",
  database = "test_db",
  uid = "postgres",
  pwd = "password",
  host = "localhost",
  port = 5432)
```

Alternatively you can pass a complete connection string as the
`.connection_string` argument. [The Connection Strings
Reference](https://www.connectionstrings.com) is a useful resource that
has example connection strings for a large variety of databases.

``` r
library(DBI)
con <- dbConnect(odbc::odbc(),
  .connection_string = "Driver={PostgreSQL Driver};Uid=postgres;Pwd=password;Host=localhost;Port=5432;Database=test_db;")
```

### DSN Configuration files

ODBC configuration files are another option to specify connection
parameters and allow one to use a Data Source Name (DSN) to make it
easier to connect to a database.

``` r
con <- dbConnect(odbc::odbc(), "PostgreSQL")
```

#### Windows

The [ODBC Data Source
Administrator](https://msdn.microsoft.com/en-us/library/ms714024\(v=vs.85\).aspx)
application is used to manage ODBC data sources on Windows.

#### MacOS / Linux

On MacOS and Linux there are two separate text files that need to be
edited. UnixODBC includes a command line executable `odbcinst` which can
be used to query and modify the DSN files. However these are plain text
files you can also edit by hand if desired.

There are two different files used to setup the DSN information.

  - `odbcinst.ini` - which defines driver options
  - `odbc.ini` - which defines connection options

The DSN configuration files can be defined globally for all users of the
system, often at `/etc/odbc.ini` or `/opt/local/etc/odbc.ini`, the exact
location depends on what option was used when compiling unixODBC.
`odbcinst -j` can be used to find the exact location. Alternatively the
`ODBCSYSINI` environment variable can be used to specify the location of
the configuration files. Ex. `ODBCSYSINI=~/ODBC`

A local DSN file can also be used with the files `~/.odbc.ini` and
`~/.odbcinst.ini`.

##### odbcinst.ini

Contains driver information, particularly the name of the driver
library. Multiple drivers can be specified in the same file.

``` ini
[PostgreSQL Driver]
Driver          = /usr/local/lib/psqlodbcw.so

[SQLite Driver]
Driver          = /usr/local/lib/libsqlite3odbc.dylib
```

##### odbc.ini

Contains connection information, particularly the username, password,
database and host information. The Driver line corresponds to the driver
defined in `odbcinst.ini`.

``` ini
[PostgreSQL]
Driver              = PostgreSQL Driver
Database            = test_db
Servername          = localhost
UserName            = postgres
Password            = password
Port                = 5432

[SQLite]
Driver          = SQLite Driver
Database=/tmp/testing
```

See also: [unixODBC without the
GUI](http://www.unixodbc.org/odbcinst.html) for more information and
examples.

## Usage

All of the following examples assume you have already created a
connection `con`. See [Connecting to a
database](#connecting-to-a-database) for more information on
establishing a connection.

### Table and Field information

`dbListTables()` is used for listing all existing tables in a database.

``` r
dbListTables(con)

# List tables beginning with f
dbListTables(con, table_name = "f%")

# List all fields in the 'flights' database
dbListFields(con, "flights")
```

### Reading

`dbReadTable()` will read a full table into an R `data.frame()`.

``` r
data <- dbReadTable(con, "flights")
```

### Writing

`dbWriteTable()` will write an R `data.frame()` to an SQL table.

``` r
data <- dbWriteTable(con, "iris", iris)
```

### Querying

`dbGetQuery()` will submit a query and fetch the results. It is also
possible to submit the query and fetch separately with `dbSendQuery()`
and `dbFetch()`. The `n=` argument to `dbFetch()` can be used to fetch
only the part of a query result (the next *n*
rows).

``` r
result <- dbSendQuery(con, "SELECT flight, tailnum, origin FROM flights ORDER BY origin")

# Retrieve the first 100 results
first_100 <- dbFetch(result, n = 100)

# Retrieve the rest of the results
rest <- dbFetch(result)
```

## Benchmarks

The *odbc* package is often much faster than the existing
[RODBC](https://cran.r-project.org/package=RODBC) and DBI compatible
[RODBCDBI](https://cran.r-project.org/package=RODBCDBI) packages.

### Reading

Reading a table from a SQL Server database with the ‘flights’ dataset
(336,776 rows, 19 columns) of the package
[nytflights13](https://github.com/hadley/nycflights13).

``` r
# First using RODBC / RODBCDBI
library(DBI)
rodbc <- dbConnect(RODBCDBI::ODBC(), dsn = "MicrosoftSQLServer", user = Sys.getenv("SQLSERVER_UID"), password = Sys.getenv("SQLSERVER_PWD"))
system.time(rodbc_result <- dbReadTable(rodbc, "flights"))
system.time(rodbc_result <- dbReadTable(rodbc, "flights"))
#>    user  system elapsed 
#>  13.986   1.173  15.192

# Now using odbc
odbc <- dbConnect(odbc::odbc(), dsn = "MicrosoftSQLServer", UID = Sys.getenv("SQLSERVER_UID"), PWD = Sys.getenv("SQLSERVER_PWD"))
system.time(odbc_result <- dbReadTable(odbc, "flights"))
#>    user  system elapsed 
#>   1.334   0.065   1.406

tibble::as_tibble(odbc_result)
#> # A tibble: 336,776 x 19
#>     year month   day dep_time sched_dep_time dep_delay arr_time
#>    <int> <int> <int>    <int>          <int>     <dbl>    <int>
#>  1  2013     1     1      517            515         2      830
#>  2  2013     1     1      533            529         4      850
#>  3  2013     1     1      542            540         2      923
#>  4  2013     1     1      544            545        -1     1004
#>  5  2013     1     1      554            600        -6      812
#>  6  2013     1     1      554            558        -4      740
#>  7  2013     1     1      555            600        -5      913
#>  8  2013     1     1      557            600        -3      709
#>  9  2013     1     1      557            600        -3      838
#> 10  2013     1     1      558            600        -2      753
#> # … with 336,766 more rows, and 12 more variables: sched_arr_time <int>,
#> #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
#> #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
#> #   minute <dbl>, time_hour <dttm>

identical(dim(rodbc_result), dim(odbc_result))
#> [1] TRUE

rm(rodbc_result, odbc_result, odbc, rodbc)
gc(verbose = FALSE)
```

### Writing

Writing the same dataset to the database.

``` r
library(nycflights13)
# rodbc does not support writing timestamps natively, so we remove that column
flights2 <- as.data.frame(flights[, names(flights) != "time_hour"])
rodbc <- dbConnect(RODBCDBI::ODBC(), dsn = "MicrosoftSQLServer", user = Sys.getenv("SQLSERVER_UID"), password = Sys.getenv("SQLSERVER_PWD"))
system.time(dbWriteTable(rodbc, "flights2", flights2))
#>    user  system elapsed
#>  11.891   6.269 765.269

# Now using odbc
odbc <- dbConnect(odbc::odbc(), dsn = "MicrosoftSQLServer", UID = Sys.getenv("SQLSERVER_UID"), PWD = Sys.getenv("SQLSERVER_PWD"))
flights3 <- as.data.frame(flights)
system.time(dbWriteTable(odbc, "flights3", flights3))
#>    user  system elapsed
#>   2.617   0.275   9.649
```
