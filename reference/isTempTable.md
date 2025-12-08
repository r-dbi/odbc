# Helper method used to determine if a table identifier is that of a temporary table.

Currently implemented only for select back-ends where we have a use for
it (SQL Server, for example). Generic, in case we develop a broader use
case.

## Usage

``` r
isTempTable(conn, name, ...)

# S4 method for class 'OdbcConnection,Id'
isTempTable(conn, name, ...)

# S4 method for class 'OdbcConnection,SQL'
isTempTable(conn, name, ...)
```

## Arguments

- conn:

  OdbcConnection

- name:

  Table name

- ...:

  additional parameters to methods
