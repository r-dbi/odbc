# SQL Server

Details of SQL Server methods for odbc and DBI generics.

### [`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html)

`conn@quote` returns the quotation mark, but quotation marks and square
brackets can be used interchangeably for delimited identifiers.
(<https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers>).
This function strips the brackets first and then calls the DBI method to
strip the quotation marks.

### [`isTempTable()`](https://odbc.r-dbi.org/dev/reference/isTempTable.md)

Local temp tables are stored as
`[tempdb].[dbo].[#name]_____[numeric identifier]`, so
[`isTempTable()`](https://odbc.r-dbi.org/dev/reference/isTempTable.md)
returns `TRUE` if `catalog_name` is `"tempdb"` or `"%"`, or the name
starts with `"#"`.

### [`dbExistsTable()`](https://dbi.r-dbi.org/reference/dbExistsTable.html)

The default implementation reports temporary tables as non-existent
since they live in a different catalog. This method provides a special
case for temporary tables, as identified by
[`isTempTable()`](https://odbc.r-dbi.org/dev/reference/isTempTable.md).

### [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)

The default implementation reports temporary tables as non-existent when
a `catalog_name` isn't supplied since they live in a different catalog.
This method provides a special case for temporary tables.

### `odbcConnectionSchemas`

Method for an internal function. Calls catalog-specific `sp_tables` to
make sure we list the schemas in the appropriate database/catalog.

### [`sqlCreateTable()`](https://dbi.r-dbi.org/reference/sqlCreateTable.html)

Warns if `temporary = TRUE` but the `name` does not conform to temp
table naming conventions (i.e. it doesn't start with `#`).

### [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)

If temp table, query the database for the actual table name.

### [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)

Copied over from odbc-connection to avoid S4 dispatch NOTEs.

## Details

Note on binding
[TVPs](https://learn.microsoft.com/en-us/sql/relational-databases/tables/use-table-valued-parameters-database-engine):
You can bind `data.frame`s to SQL Server TVPs when executing stored
procedures with the following caveats:

- All non-df parameters must be of length 1; and

- The `batch_rows` parameter (to `dbBind`, for example) should be set to
  1.

## Examples

``` r
if (FALSE) { # \dontrun{
# Bind `data.frame` to a TVP when executing a
# stored procedure that takes three parameters:
# a TVP, an INT and a VARCHAR(max).
res <- dbGetQuery(conn, "{ CALL example_sproc(?, ?, ?) }",
  params = list(df.data, 100, "Lorem ipsum dolor sit amet"))
} # }
```
