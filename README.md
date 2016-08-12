
<!-- README.md is generated from README.Rmd. Please edit that file -->
odbconnect
==========

[![Travis-CI Build Status](https://travis-ci.org/hadley/odbconnect.svg?branch=master)](https://travis-ci.org/hadley/odbconnect) [![Coverage Status](https://img.shields.io/codecov/c/github/hadley/odbconnect/master.svg)](https://codecov.io/github/hadley/odbconnect?branch=master)

The goal of odbconnect is to provide a DBI-compliant interface to ODBC drivers.

The current implementation uses a modified version of the cpp\_odbc and turbodbc libraries from the [turbodbc](https://github.com/blue-yonder/turbodbc) python package.

Benchmarks vs RODBC / RODBCDBI
------------------------------

Simply reading a postgres table with the nytflights13 'flights' database.

``` r
# First using RODBC / RODBCDBI
library(DBI)
library(RODBCDBI)
rodbc <- dbConnect(RODBCDBI::ODBC(), dsn = "PostgreSQL")
rodbc_query <- dbSendQuery(rodbc, "SELECT * from flights")
system.time(rodbc_result <- dbFetch(rodbc_query))
#>    user  system elapsed 
#>  12.758   2.428  16.451

# Now using odbconnect
library(odbconnect)
odbconnect <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
odbconnect_query <- dbSendQuery(odbconnect, "SELECT * from flights")
system.time(odbconnect_result <- dbFetch(odbconnect_query))
#>    user  system elapsed 
#>   2.410   0.133   2.852

library(tibble)
as_tibble(odbconnect_result)
#> # A tibble: 336,776 x 19
#>     year month   day dep_time sched_dep_time dep_delay arr_time
#>    <int> <int> <int>    <int>          <int>     <dbl>    <int>
#> 1   2013     1     1      517            515         2      830
#> 2   2013     1     1      533            529         4      850
#> 3   2013     1     1      542            540         2      923
#> 4   2013     1     1      544            545        -1     1004
#> 5   2013     1     1      554            600        -6      812
#> 6   2013     1     1      554            558        -4      740
#> 7   2013     1     1      555            600        -5      913
#> 8   2013     1     1      557            600        -3      709
#> 9   2013     1     1      557            600        -3      838
#> 10  2013     1     1      558            600        -2      753
#> # ... with 336,766 more rows, and 12 more variables: sched_arr_time <int>,
#> #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
#> #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
#> #   minute <dbl>, time_hour <dttm>

identical(dim(rodbc_result), dim(odbconnect_result))
#> [1] TRUE
```

ODBC Documentation
------------------

<https://msdn.microsoft.com/en-us/library/ms712628(v=vs.85).aspx> <https://msdn.microsoft.com/en-us/library/ms714086(v=vs.85).aspx>
