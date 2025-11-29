# Oracle

Details of Oracle methods for odbc and DBI generics.

### `odbcConnectionTables()`

Method for an internal function that otherwise relies on the `SQLTables`
ODBC API. While this method is much faster than the OEM implementation,
it does not look through synonyms.

### [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)

Query, rather than use `SQLColumns` ODBC API, since we bind a `BIGINT`
to one of the column results and Oracle's OEM driver can't handle it.

## Usage

``` r
# S4 method for class 'Oracle'
sqlCreateTable(
  con,
  table,
  fields,
  row.names = NA,
  temporary = FALSE,
  ...,
  field.types = NULL
)

# S4 method for class 'Oracle,character'
odbcConnectionTables(
  conn,
  name,
  catalog_name = NULL,
  schema_name = NULL,
  table_type = NULL,
  exact = FALSE
)
```
