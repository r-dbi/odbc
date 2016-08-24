
<!-- README.md is generated from README.Rmd. Please edit that file -->
odbconnect
==========

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Travis-CI Build Status](https://travis-ci.org/hadley/odbconnect.svg?branch=master)](https://travis-ci.org/hadley/odbconnect) [![Coverage Status](https://img.shields.io/codecov/c/github/hadley/odbconnect/master.svg)](https://codecov.io/github/hadley/odbconnect?branch=master)

The goal of odbconnect is to provide a DBI-compliant interface to ODBC drivers.

The current implementation uses a modified version of the cpp\_odbc and turbodbc libraries from the [turbodbc](https://github.com/blue-yonder/turbodbc) python package.

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
#>  12.063   2.193  15.495

# Now using odbconnect
library(odbconnect)
odbconnect <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
system.time(odbconnect_result <- dbReadTable(odbconnect, "flights"))
#> Warning in dbClearResult(rs): Result already cleared
#>    user  system elapsed 
#>   2.519   0.181   3.000

library(tibble)
as_tibble(odbconnect_result)
#> # A tibble: 336,776 × 19
#>     year month   day dep_time sched_dep_time dep_delay arr_time
#>    <int> <int> <int>    <int>          <int>     <dbl>    <int>
#> 1   2013     1     7     1252           1300        -8     1405
#> 2   2013     1     7     1252           1300        -8     1418
#> 3   2013     1     7     1253           1259        -6     1503
#> 4   2013     1     7     1254           1300        -6     1339
#> 5   2013     1     7     1255           1259        -4     1410
#> 6   2013     1     7     1255           1059       116     1400
#> 7   2013     1     7     1255           1300        -5     1538
#> 8   2013     1     7     1256           1130        86     1540
#> 9   2013     1     7     1256           1300        -4     1537
#> 10  2013     1     7     1258           1259        -1     1355
#> # ... with 336,766 more rows, and 12 more variables: sched_arr_time <int>,
#> #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
#> #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
#> #   minute <dbl>, time_hour <dttm>

identical(dim(rodbc_result), dim(odbconnect_result))
#> [1] TRUE
rm(rodbc_result, odbconnect_result)
gc()
#>          used (Mb) gc trigger (Mb) max used  (Mb)
#> Ncells 474586 25.4     940480 50.3   940480  50.3
#> Vcells 989359  7.6   11732058 89.6 18239270 139.2
```

### Writing

Writing the flights database works as well.

``` r
library(nycflights13)
# rodbc does not support writing timestamps natively.
system.time(dbWriteTable(rodbc, "flights2", as.data.frame(flights[, names(flights) != "time_hour"])))
#>    user  system elapsed 
#>   7.067   3.813  47.068

# Now using odbconnect
odbconnect <- dbConnect(odbconnect::odbconnect(), dsn = "PostgreSQL")
system.time(dbWriteTable(odbconnect, "flights3", as.data.frame(flights)))
#> Warning in dbClearResult(rs): Result already cleared

#> Warning in dbClearResult(rs): Result already cleared
#>    user  system elapsed 
#>   8.168  11.462  34.150
```

ODBC Documentation
------------------

<https://msdn.microsoft.com/en-us/library/ms712628(v=vs.85).aspx> <https://msdn.microsoft.com/en-us/library/ms714086(v=vs.85).aspx>
