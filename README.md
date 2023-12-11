
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
[DBI](https://dbi.r-dbi.org/)-compliant interface to [Open Database
Connectivity](https://learn.microsoft.com/en-us/sql/odbc/microsoft-open-database-connectivity-odbc?view=sql-server-ver15)
(ODBC) drivers. This allows for an efficient, easy to setup connection
to any database with support for ODBC.

## Overview

The odbc package is one piece of the R interface to databases with
support for ODBC:

<img src="man/figures/whole-game.png" alt="A diagram containing four boxes with arrows linking each pointing left to right. The boxes read, in order, &quot;R interface,&quot; &quot;driver manager,&quot; &quot;ODBC driver,&quot; and &quot;DBMS.&quot; The left-most box, R interface, contains three smaller components, labeled &quot;dbplyr,&quot; &quot;DBI,&quot; and &quot;odbc.&quot;" width="1527" />

The package supports any **Database Management System (DBMS)** with ODBC
support, including [SQL
Server](https://www.microsoft.com/en-us/sql-server/),
[Oracle](https://www.oracle.com/database),
[MySQL](https://www.mysql.com/),
[PostgreSQL](https://www.postgresql.org/),
[Databricks](https://www.databricks.com/),
[Snowflake](https://www.snowflake.com/), and others.

Support for a given DBMS is provided by an **ODBC driver**, which
defines how to interact with that DBMS using the standardized syntax of
ODBC and SQL. Drivers can be downloaded from the DBMS vendor or, if
you’re a Posit customer, using the [professional
drivers](https://docs.posit.co/pro-drivers/).

One of the central benefits of ODBC is its interoperability; any DBMS
with drivers available is accessible through ODBC. To manage information
about these drivers and the data sources they provide access to, our
computers use a **driver manager**. Windows is bundled with a driver
manager, while MacOS and Linux require installation of one; the ODBC
package supports the [unixODBC](https://www.unixodbc.org/) driver
manager.

In the **R interface**, the [DBI package](https://dbi.r-dbi.org/)
provides a front-end while odbc implements a back-end to communicate
with the driver manager. The odbc package is built on top of the
[nanodbc](https://nanodbc.github.io/nanodbc/) C++ library. To interface
with DBMSs using R and odbc:

<img src="man/figures/r-interface.png" alt="A diagram showing a high-level workflow for using the R interface in 3 steps. In step 1, configure drivers and data sources, the functions odbcListDrivers() and odbcListDataSources() help to interface with the driver manager. In step 2, the dbConnect() function, called with the first argument odbc(), connects to a database using the specified ODBC driver to create a connection object &quot;con.&quot; Finally, in step 3, that connection object can be passed to various functions to retrieve information on database structure, iteratively develop queries, and query data objects." width="1824" />

The “Installing and Configuring Drivers” vignette at `vignette("setup")`
gives example code for establishing a connection `con` for several
different DBMSs. See the [Usage section](#usage) below for example code.

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

All of the following examples assume you have already created a
connection `con`. See the “Installing and Configuring Drivers” vignette
for more information on establishing a connection.

<!-- TODO: link to the deployed vignette above -->

`dbListTables()` is used for listing all existing tables in a database.

``` r
dbListTables(con)

# List tables beginning with f
dbListTables(con, table_name = "f%")

# List all fields in the 'flights' database
dbListFields(con, "flights")
```

`dbReadTable()` will read a full table into an R `data.frame()`.

``` r
data <- dbReadTable(con, "flights")
```

`dbWriteTable()` will write an R `data.frame()` to an SQL table.

``` r
dbWriteTable(con, "iris", iris)
```

`dbGetQuery()` will submit a SQL query and fetch the results. It is also
possible to submit the query and fetch separately with `dbSendQuery()`
and `dbFetch()`. The `n` argument to `dbFetch()` can be used to fetch
only part of a query result (the next *n* rows).

``` r
result <- 
  dbSendQuery(
    con, 
    "SELECT flight, tailnum, origin FROM flights ORDER BY origin"
  )

# Retrieve the first 100 results
first_100 <- dbFetch(result, n = 100)

# Retrieve the rest of the results
rest <- dbFetch(result)
```

To generate SQL code using dplyr syntax, see the [dbplyr
package](https://dbplyr.tidyverse.org/).

The odbc package is often much faster than the existing
[RODBC](https://cran.r-project.org/package=RODBC) and DBI compatible
[RODBCDBI](https://cran.r-project.org/package=RODBCDBI) packages. See
`vignette("benchmarks")` to learn more.
