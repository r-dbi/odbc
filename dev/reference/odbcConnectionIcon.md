# Get an icon representing a connection.

**\[deprecated\]** Return the path on disk to an icon representing a
connection.

## Usage

``` r
odbcConnectionIcon(connection)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## Value

The path to an icon file on disk.

## Details

The icon returned should be a 32x32 square image file.
