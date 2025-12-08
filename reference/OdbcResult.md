# Odbc Result Methods

Implementations of pure virtual functions defined in the `DBI` package
for OdbcResult objects.

## Usage

``` r
# S4 method for class 'OdbcResult'
dbClearResult(res, ...)

# S4 method for class 'OdbcResult'
dbFetch(res, n = -1, ...)

# S4 method for class 'OdbcResult'
dbHasCompleted(res, ...)

# S4 method for class 'OdbcResult'
dbIsValid(dbObj, ...)

# S4 method for class 'OdbcResult'
dbGetStatement(res, ...)

# S4 method for class 'OdbcResult'
dbColumnInfo(res, ...)

# S4 method for class 'OdbcResult'
dbGetRowCount(res, ...)

# S4 method for class 'OdbcResult'
dbGetRowsAffected(res, ...)

# S4 method for class 'OdbcResult'
dbBind(res, params, ..., batch_rows = getOption("odbc.batch_rows", NA))
```

## Arguments

- res:

  An object inheriting from
  [DBI::DBIResult](https://dbi.r-dbi.org/reference/DBIResult-class.html).

- ...:

  Other arguments passed on to methods.

- n:

  maximum number of records to retrieve per fetch. Use `n = -1` or
  `n = Inf` to retrieve all pending records. Some implementations may
  recognize other special values.

- dbObj:

  An object inheriting from `DBIObject`, i.e. `DBIDriver`,
  `DBIConnection`, or a `DBIResult`.

- params:

  For [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html), a list
  of values, named or unnamed, or a data frame, with one element/column
  per query parameter. For
  [`dbBindArrow()`](https://dbi.r-dbi.org/reference/dbBind.html), values
  as a nanoarrow stream, with one column per query parameter.

- batch_rows:

  The number of rows to retrieve. Defaults to `NA`, which is set
  dynamically to the minimum of 1024 and the size of the input.
  Depending on the database, driver, dataset and free memory, setting
  this to a lower value may improve performance.
