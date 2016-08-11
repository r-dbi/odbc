
<!-- README.md is generated from README.Rmd. Please edit that file -->
odbconnect
==========

The goal of odbconnect is to provide a DBI-compliant interface to ODBC drivers.

The current implementation uses a modified version of the cpp\_odbc and turbodbc libraries from the [turbodbc](https://github.com/blue-yonder/turbodbc) python package.

Benchmarks vs RODBC / RODBCDBI
------------------------------

Simply reading a postgres table with the nytflights13 'flights' database.

``` r
# First using RODBC / RODBCDBI
library(DBI)
library(RODBCDBI)
rodbc <- dbConnect(RODBCDBI::ODBC(), dsn="database1")
rodbc_query <- dbSendQuery(rodbc, "SELECT * from flights")
system.time(rodbc_result <- dbFetch(rodbc_query))
#> Warning: closing unused RODBC handle 2
#>    user  system elapsed 
#>  11.190   2.126  13.500

# Now using odbconnect
library(odbconnect)
odbconnect <- dbConnect(odbconnect::odbconnect(), "DSN=database1")
odbconnect_query <- dbSendQuery(odbconnect, "SELECT * from flights")
system.time(odbconnect_result <- dbFetch(odbconnect_query))
#>    user  system elapsed 
#>   1.261   0.030   1.304

odbconnect_result
#> # A tibble: 336,776 x 19
#>     year month   day dep_time sched_dep_time dep_delay arr_time
#>    <int> <int> <int>    <int>          <int>     <dbl>    <int>
#> 1   2013     1     2      659            700        -1      959
#> 2   2013     1     2      700            630        30      917
#> 3   2013     1     2      700            700         0      851
#> 4   2013     1     2      700            700         0     1017
#> 5   2013     1     2      701            705        -4     1001
#> 6   2013     1     2      702            700         2     1054
#> 7   2013     1     2      704            655         9      947
#> 8   2013     1     2      704            705        -1      908
#> 9   2013     1     2      704            700         4     1142
#> 10  2013     1     2      705            630        35     1209
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
