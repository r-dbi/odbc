# List remote tables and fields for an ODBC connection

[`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
provides names of remote tables accessible through this connection;
[`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
provides names of columns within a table.

## Usage

``` r
# S4 method for class 'OdbcConnection'
dbListTables(
  conn,
  catalog_name = NULL,
  schema_name = NULL,
  table_name = NULL,
  table_type = NULL,
  ...
)
```

## Arguments

- conn:

  A
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- catalog_name, schema_name, table_name:

  Catalog, schema, and table names.

  By default, `catalog_name`, `schema_name` and `table_name` will
  automatically escape underscores to ensure that you match exactly one
  table. If you want to search for multiple tables using wild cards, you
  will need to use `odbcConnectionTables()` directly instead.

- table_type:

  The type of the table to return, the default returns all table types.

- ...:

  Other parameters passed on to methods.

## Value

A character vector of table or field names respectively.
