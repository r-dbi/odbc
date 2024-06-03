
<!-- README.md is generated from README.Rmd. Please edit that file -->

# odbc

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](http://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/odbc)](https://cran.r-project.org/package=odbc)
[![R-CMD-check](https://github.com/r-dbi/odbc/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-dbi/odbc/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/r-dbi/odbc/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-dbi/odbc?branch=main)
<!-- badges: end -->

The goal of the odbc package is to provide a
[DBI](https://dbi.r-dbi.org/)-compliant interface to
[ODBC](https://learn.microsoft.com/en-us/sql/odbc/microsoft-open-database-connectivity-odbc)
drivers. This makes it easy to connect databases such as [SQL
Server](https://www.microsoft.com/en-us/sql-server/),
Oracle,
[Databricks](https://www.databricks.com/), and
Snowflake.

The odbc package is an alternative to
[RODBC](https://cran.r-project.org/package=RODBC) and
[RODBCDBI](https://cran.r-project.org/package=RODBCDBI) packages, and is
typically much faster. See `vignette("benchmarks")` to learn more.

## Overview

The odbc package is one piece of the R interface to databases with
support for ODBC:

<img src="man/figures/whole-game.png" alt="A diagram containing four boxes with arrows linking each pointing left to right. The boxes read, in order, &quot;R interface,&quot; &quot;driver manager,&quot; &quot;ODBC driver,&quot; and &quot;DBMS.&quot; The left-most box, R interface, contains three smaller components, labeled &quot;dbplyr,&quot; &quot;DBI,&quot; and &quot;odbc.&quot;" width="1489" />

Support for a given DBMS is provided by an **ODBC driver**, which
defines how to interact with that DBMS using the standardized syntax of
ODBC and SQL. Drivers can be downloaded from the DBMS vendor or, if
you’re a Posit customer, using the [professional
drivers](https://docs.posit.co/pro-drivers/).

Drivers are managed by a **driver manager**, which is responsible for
configuring driver locations, and optionally named **data sources** that
describe how to connect to a specific database. Windows is bundled with
a driver manager, while MacOS and Linux require installation of
[unixODBC](https://www.unixodbc.org/). Drivers often require some manual
configuration; see `vignette("setup")` for details.

In the **R interface**, the [DBI package](https://dbi.r-dbi.org/)
provides a front-end while odbc implements a back-end to communicate
with the driver manager. The odbc package is built on top of the
[nanodbc](https://nanodbc.github.io/nanodbc/) C++ library. To interface
with DBMSs using R and odbc:

<img src="man/figures/r-interface.png" alt="A high-level workflow for using the R interface in 3 steps. In step 1, configure drivers and data sources, the functions odbcListDrivers() and odbcListDataSources() help to interface with the driver manager. In step 2, the dbConnect() function, called with the first argument odbc(), connects to a database using the specified ODBC driver to create a connection object &quot;con.&quot; Finally, in step 3, that connection object can be passed to various functions to retrieve information on database structure, iteratively develop queries, and query data objects." width="1302" />

You might also use the [dbplyr package](https://dbplyr.tidyverse.org/)
to automatically generate SQL from your dplyr code.

## Installation

Install the latest release of odbc from CRAN with the following code:

``` r
install.packages("odbc")
```

To get a bug fix or to use a feature from the development version, you
can install the development version of odbc from GitHub:

``` r
# install.packages("pak")
pak::pak("r-dbi/odbc")
```

## Usage

To use odbc, begin by creating a database connection, which might look
something like this:

``` r
library(DBI)

con <- dbConnect(
  odbc::odbc(),
  driver = "SQL Server",
  server = "my-server",
  database = "my-database",
  uid = "my-username",
  pwd = rstudioapi::askForPassword("Database password")
)
```

(See `vignette("setup")` for examples of connecting to a variety of
databases.)

`dbListTables()` is used for listing all existing tables in a database.

``` r
dbListTables(con)
```

`dbReadTable()` will read a full table into an R `data.frame()`.

``` r
data <- dbReadTable(con, "flights")
```

`dbWriteTable()` will write an R `data.frame()` to an SQL table.

``` r
dbWriteTable(con, "iris", iris)
```

`dbGetQuery()` will submit a SQL query and fetch the results:

``` r
df <- dbGetQuery(
  con,
  "SELECT flight, tailnum, origin FROM flights ORDER BY origin"
)
```

It is also possible to submit the query and fetch separately with
`dbSendQuery()` and `dbFetch()`. This allows you to use the `n` argument
to `dbFetch()` to iterate over results that would otherwise be too large
to fit in memory.
