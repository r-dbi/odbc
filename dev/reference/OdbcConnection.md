# Odbc Connection Methods

Implementations of pure virtual functions defined in the `DBI` package
for OdbcConnection objects.

## Usage

``` r
# S4 method for class 'OdbcConnection'
show(object)

# S4 method for class 'OdbcConnection'
dbIsValid(dbObj, ...)

# S4 method for class 'OdbcConnection'
dbDisconnect(conn, ...)

# S4 method for class 'OdbcConnection,character'
dbSendQuery(conn, statement, params = NULL, ..., immediate = FALSE)

# S4 method for class 'OdbcConnection,character'
dbExecute(conn, statement, params = NULL, ..., immediate = is.null(params))

# S4 method for class 'OdbcConnection,character'
dbSendStatement(conn, statement, params = NULL, ..., immediate = FALSE)

# S4 method for class 'OdbcConnection,ANY'
dbDataType(dbObj, obj, ...)

# S4 method for class 'OdbcConnection,data.frame'
dbDataType(dbObj, obj, ...)

# S4 method for class 'OdbcConnection,character'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'OdbcConnection,SQL'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'OdbcConnection'
dbGetInfo(dbObj, ...)

# S4 method for class 'OdbcConnection,character'
dbGetQuery(
  conn,
  statement,
  n = -1,
  params = NULL,
  immediate = is.null(params),
  ...
)

# S4 method for class 'OdbcConnection'
dbBegin(conn, ...)

# S4 method for class 'OdbcConnection'
dbCommit(conn, ...)

# S4 method for class 'OdbcConnection'
dbRollback(conn, ...)

# S4 method for class 'OdbcConnection,Id'
dbListFields(conn, name, ...)

# S4 method for class 'OdbcConnection,SQL'
dbListFields(conn, name, ...)

# S4 method for class 'OdbcConnection,character'
dbListFields(
  conn,
  name,
  catalog_name = NULL,
  schema_name = NULL,
  column_name = NULL,
  ...
)

# S4 method for class 'OdbcConnection,Id'
dbExistsTable(conn, name, ...)

# S4 method for class 'OdbcConnection,SQL'
dbExistsTable(conn, name, ...)

# S4 method for class 'OdbcConnection,character'
dbExistsTable(conn, name, ...)

# S4 method for class 'OdbcConnection,character'
dbRemoveTable(conn, name, ...)
```

## Arguments

- object:

  Any R object

- dbObj:

  An object inheriting from `DBIObject`, i.e. `DBIDriver`,
  `DBIConnection`, or a `DBIResult`.

- ...:

  Other arguments to methods.

- conn:

  A
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- statement:

  a character string containing SQL.

- params:

  Query parameters to pass to
  [`DBI::dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html). See
  [`DBI::dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html) for
  details.

- immediate:

  If `TRUE`, SQLExecDirect will be used instead of SQLPrepare, and the
  `params` argument is ignored

- obj:

  An R object whose SQL type we want to determine.

- x:

  A character vector, [SQL](https://dbi.r-dbi.org/reference/SQL.html) or
  [Id](https://dbi.r-dbi.org/reference/Id.html) object to quote as
  identifier.

- n:

  maximum number of records to retrieve per fetch. Use `n = -1` or
  `n = Inf` to retrieve all pending records. Some implementations may
  recognize other special values.

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

- catalog_name:

  Catalog where table is located.

- schema_name:

  Schema where table is located.

- column_name:

  The name of the column to return, the default returns all columns.
