
<!-- README.md is generated from README.Rmd. Please edit that file -->
odbconnect
==========

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Travis-CI Build Status](https://travis-ci.org/rstats-db/odbconnect.svg?branch=master)](https://travis-ci.org/rstats-db/odbconnect) [![Coverage Status](https://img.shields.io/codecov/c/github/rstats-db/odbconnect/master.svg)](https://codecov.io/github/rstats-db/odbconnect?branch=master) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/rstats-db/odbconnect?branch=master&svg=true)](https://ci.appveyor.com/project/rstats-db/odbconnect)

The goal of odbconnect is to provide a DBI-compliant interface to ODBC drivers. The current implementation uses the [nanodbc](http://nanodbc.lexicalunit.com/) C++ library.

Benchmarks vs RODBC / RODBCDBI
------------------------------

### Reading

Simply reading a postgres table with the nytflights13 'flights' database.

``` r
# First using RODBC / RODBCDBI
library(DBI)
library(RODBCDBI)
rodbc <- dbConnect(RODBCDBI::ODBC(), dsn = "PostgreSQL")
system.time(rodbc_result <- dbReadTable(rodbc, "flights"))
#>    user  system elapsed 
#>  20.418   1.374  23.045

# Now using odbconnect
library(odbconnect)
odbconnect <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
system.time(odbconnect_result <- dbReadTable(odbconnect, "flights"))
#>    user  system elapsed 
#>   4.999   0.293   6.653

library(tibble)
as_tibble(odbconnect_result)
#> # A tibble: 336,776 × 20
#>    row.names  year month   day dep_time sched_dep_time dep_delay arr_time
#>        <chr> <int> <int> <int>    <int>          <int>     <dbl>    <int>
#> 1          1  2013     1     1      517            515         2      830
#> 2          2  2013     1     1      533            529         4      850
#> 3          3  2013     1     1      542            540         2      923
#> 4          4  2013     1     1      544            545        -1     1004
#> 5          5  2013     1     1      554            600        -6      812
#> 6          6  2013     1     1      554            558        -4      740
#> 7          7  2013     1     1      555            600        -5      913
#> 8          8  2013     1     1      557            600        -3      709
#> 9          9  2013     1     1      557            600        -3      838
#> 10        10  2013     1     1      558            600        -2      753
#> # ... with 336,766 more rows, and 12 more variables: sched_arr_time <int>,
#> #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
#> #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
#> #   minute <dbl>, time_hour <dttm>

identical(dim(rodbc_result), dim(odbconnect_result))
#> [1] TRUE
rm(rodbc_result, odbconnect_result)
gc()
#>           used (Mb) gc trigger  (Mb) max used  (Mb)
#> Ncells  506621 27.1    1442291  77.1  1022552  54.7
#> Vcells 2020237 15.5   15230056 116.2 23665584 180.6
```

### Writing

Writing the flights database works as well.

``` r
library(nycflights13)
# rodbc does not support writing timestamps natively.
system.time(dbWriteTable(rodbc, "flights2", as.data.frame(flights[, names(flights) != "time_hour"])))
#>    user  system elapsed 
#>   7.298   4.166  48.932

# Now using odbconnect
odbconnect <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
system.time(dbWriteTable(odbconnect, "flights3", as.data.frame(flights)))
#>    user  system elapsed 
#>   7.875   3.823  26.217
```

ODBC Documentation
------------------

<https://msdn.microsoft.com/en-us/library/ms712628(v=vs.85).aspx> <https://msdn.microsoft.com/en-us/library/ms714086(v=vs.85).aspx>
