# Preview the data in an object.

Return the data inside an object as a data frame.

## Usage

``` r
odbcPreviewObject(connection, rowLimit, ...)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- rowLimit:

  The maximum number of rows to display.

- ...:

  Parameters specifying the object.

## Value

A data frame containing the data in the object.

## Details

The object to previewed must be specified as one of the arguments (e.g.
`table = "employees"`); depending on the driver and underlying data
store, additional specification arguments may be required.
