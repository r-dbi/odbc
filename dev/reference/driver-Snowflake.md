# Connecting to Snowflake via ODBC

### [`odbcConnectionColumns()`](https://odbc.r-dbi.org/dev/reference/odbcConnectionColumns.md)

If the catalog, or the schema arguments are NULL, attempt to infer by
querying for CURRENT_DATABASE() and CURRENT_SCHEMA(). We do this to aid
with performance, as the SQLColumns method is more performant when
restricted to a particular DB/schema.

## Usage

``` r
# S4 method for class 'Snowflake,character'
dbExistsTableForWrite(conn, name, ..., catalog_name = NULL, schema_name = NULL)
```

## Arguments

- conn:

  A
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- name:

  The table name, passed on to
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html).
  Options are:

  - a character string with the unquoted DBMS table name, e.g.
    `"table_name"`,

  - a call to [`Id()`](https://dbi.r-dbi.org/reference/Id.html) with
    components to the fully qualified table name, e.g.
    `Id(schema = "my_schema", table = "table_name")`

  - a call to [`SQL()`](https://dbi.r-dbi.org/reference/SQL.html) with
    the quoted and fully qualified table name given verbatim, e.g.
    `SQL('"my_schema"."table_name"')`

- ...:

  Other parameters passed on to methods.

- catalog_name, schema_name:

  Catalog and schema names.
