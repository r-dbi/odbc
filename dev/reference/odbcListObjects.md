# List objects in a connection.

Lists all of the objects in the connection, or all the objects which
have specific attributes.

## Usage

``` r
odbcListObjects(connection, ...)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- ...:

  Attributes to filter by.

## Value

A data frame with `name` and `type` columns, listing the objects.

## Details

When used without parameters, this function returns all of the objects
known by the connection. Any parameters passed will filter the list to
only objects which have the given attributes; for instance, passing
`schema = "foo"` will return only objects matching the schema `foo`.
