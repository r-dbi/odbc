# Odbc Driver Methods

Implementations of pure virtual functions defined in the `DBI` package
for OdbcDriver objects.

## Usage

``` r
# S4 method for class 'OdbcDriver'
show(object)

# S4 method for class 'OdbcDriver,ANY'
dbDataType(dbObj, obj, ...)

# S4 method for class 'OdbcDriver,list'
dbDataType(dbObj, obj, ...)

# S4 method for class 'OdbcDriver,data.frame'
dbDataType(dbObj, obj, ...)

# S4 method for class 'OdbcDriver'
dbIsValid(dbObj, ...)

# S4 method for class 'OdbcDriver'
dbGetInfo(dbObj, ...)
```

## Arguments

- object:

  Any R object

- dbObj:

  A object inheriting from
  [DBI::DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html)
  or
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)

- obj:

  An R object whose SQL type we want to determine.

- ...:

  Other arguments passed on to methods.
