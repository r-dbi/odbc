# Benchmarks

The odbc package is often much faster than the existing
[RODBC](https://cran.r-project.org/package=RODBC) and DBI compatible
[RODBCDBI](https://cran.r-project.org/package=RODBCDBI) packages. We’ll
benchmark writing and reading data from the
[nycflights13](https://github.com/tidyverse/nycflights13) package using
the three packages.

``` r
library(odbc)
library(RODBC)
library(RODBCDBI)

library(DBI)

library(nycflights13)
```

## Setup

RODBC and RODBCDBI trip up on `flights`’ tibble subclass, so we’ll
convert it to a data frame before passing to each package. Also, the
RODBCDBI package does not support writing timestamps, so we remove that
column as well.

``` r
flights$time_hour <- NULL
flights <- as.data.frame(flights)
```

Now, let’s configure three driver connections to a Microsoft SQL Server
database, one for each package we’ll be benchmarking.

``` r
odbc <- dbConnect(odbc::odbc(), dsn = "MicrosoftSQLServer", uid = "SA", pwd = "BoopBop123!")
rodbc <- RODBC::odbcConnect(dsn = "MicrosoftSQLServer", uid = "SA", pwd = "BoopBop123!")
rodbcdbi <- dbConnect(RODBCDBI::ODBC(), dsn = "MicrosoftSQLServer", user = "SA", password = "BoopBop123!")
```

The above code requires a `dsn` `MicrosoftSQLServer` to have been
previously configured; see `vignettes("setup")` to learn more.

## Writing

We’ll first benchmark writing the flights dataset, which contains
~300,000 rows and 18 columns, to a database.

The code for odbc and RODBCDBI looks quite similar, as they both use the
DBI front-end:

``` r
odbc_write <- system.time(dbWriteTable(odbc, "flights", flights))

odbc_write
```

``` r
#>   user  system elapsed 
#>  0.883   0.176   8.108 
```

``` r
rodbcdbi_write <- system.time(dbWriteTable(rodbcdbi, "flights", flights))

rodbcdbi_write
```

``` r
#>   user  system elapsed 
#>  8.287  11.107 257.841 
```

The timings for RODBC and RODBCDBI are quite similar, as they both
utilize the RODBC back-end:

``` r
rodbc_write <- system.time(sqlSave(rodbc, flights, "flights"))

rodbc_write
```

``` r
#>   user  system elapsed 
#>  8.266  11.023 235.825 
```

## Reading

Again, the syntax for odbc and RODBCDBI is identical, while the timings
for RODBCDBI and RODBC are quite similar.

``` r
odbc_read     <- system.time(result <- dbReadTable(odbc, "flights"))
rodbcdbi_read <- system.time(result <- dbReadTable(rodbcdbi, "flights"))
rodbc_read    <- system.time(result <- sqlFetch(rodbc, "flights"))
```

``` r
odbc_read
```

``` r
#>   user  system elapsed 
#>  0.515   0.024   0.557 
```

``` r
rodbcdbi_read
```

``` r
#>   user  system elapsed 
#>  1.308   0.035   1.356 
```

``` r
rodbc_read
```

``` r
#>   user  system elapsed 
#>  1.291   0.033   1.343 
```
