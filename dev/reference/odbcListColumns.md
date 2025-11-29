# List columns in an object.

Lists the names and types of each column (field) of a specified object.

## Usage

``` r
odbcListColumns(connection, ...)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- ...:

  Parameters specifying the object.

## Value

A data frame with `name` and `type` columns, listing the object's
fields.

## Details

The object to inspect must be specified as one of the arguments (e.g.
`table = "employees"`); depending on the driver and underlying data
store, additional specification arguments may be required.
