# Return the object hierarchy supported by a connection.

Lists the object types and metadata known by the connection, and how
those object types relate to each other.

## Usage

``` r
odbcListObjectTypes(connection)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## Value

The hierarchy of object types supported by the connection.

## Details

The returned hierarchy takes the form of a nested list, in which each
object type supported by the connection is a named list with the
following attributes:

- contains:

  A list of other object types contained by the object, or "data" if the
  object contains data

- icon:

  An optional path to an icon representing the type

For instance, a connection in which the top-level object is a schema
that contains tables and views, the function will return a list like the
following:

    list(schema = list(contains = list(
                       list(name = "table", contains = "data")
                       list(name = "view", contains = "data"))))
