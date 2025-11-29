# Convenience functions for reading/writing DBMS tables

Convenience functions for reading/writing DBMS tables

## Usage

``` r
# S4 method for class 'OdbcConnection,character,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  overwrite = FALSE,
  append = FALSE,
  temporary = FALSE,
  row.names = NULL,
  field.types = NULL,
  batch_rows = getOption("odbc.batch_rows", NA),
  ...
)

# S4 method for class 'OdbcConnection,Id,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  overwrite = FALSE,
  append = FALSE,
  temporary = FALSE,
  row.names = NULL,
  field.types = NULL,
  batch_rows = getOption("odbc.batch_rows", NA),
  ...
)

# S4 method for class 'OdbcConnection,SQL,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  overwrite = FALSE,
  append = FALSE,
  temporary = FALSE,
  row.names = NULL,
  field.types = NULL,
  batch_rows = getOption("odbc.batch_rows", NA),
  ...
)

# S4 method for class 'OdbcConnection'
dbAppendTable(
  conn,
  name,
  value,
  batch_rows = getOption("odbc.batch_rows", NA),
  ...,
  row.names = NULL
)

# S4 method for class 'OdbcConnection'
sqlCreateTable(
  con,
  table,
  fields,
  row.names = NA,
  temporary = FALSE,
  ...,
  field.types = NULL
)
```

## Arguments

- conn:

  An
  [OdbcConnection](https://odbc.r-dbi.org/dev/reference/OdbcConnection.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- name:

  a character string specifying a table name. Names will be
  automatically quoted so you can use any sequence of characters, not
  just any valid bare table name.

- value:

  A data.frame to write to the database.

- overwrite:

  Allow overwriting the destination table. Cannot be `TRUE` if `append`
  is also `TRUE`.

- append:

  Allow appending to the destination table. Cannot be `TRUE` if
  `overwrite` is also `TRUE`.

- temporary:

  If `TRUE`, will generate a temporary table.

- row.names:

  Either `TRUE`, `FALSE`, `NA` or a string.

  If `TRUE`, always translate row names to a column called "row_names".
  If `FALSE`, never translate row names. If `NA`, translate rownames
  only if they're a character vector.

  A string is equivalent to `TRUE`, but allows you to override the
  default name.

  For backward compatibility, `NULL` is equivalent to `FALSE`.

- field.types:

  Additional field types used to override derived types.

- batch_rows:

  The number of rows to retrieve. Defaults to `NA`, which is set
  dynamically to the minimum of 1024 and the size of the input.
  Depending on the database, driver, dataset and free memory, setting
  this to a lower value may improve performance.

- ...:

  Other arguments used by individual methods.

- con:

  A database connection.

- table:

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

- fields:

  Either a character vector or a data frame.

  A named character vector: Names are column names, values are types.
  Names are escaped with
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html).
  Field types are unescaped.

  A data frame: field types are generated using
  [`dbDataType()`](https://dbi.r-dbi.org/reference/dbDataType.html).

## Examples

``` r
if (FALSE) { # \dontrun{
library(DBI)
con <- dbConnect(odbc::odbc())
dbListTables(con)
dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
dbReadTable(con, "mtcars")

dbListTables(con)
dbExistsTable(con, "mtcars")

# A zero row data frame just creates a table definition.
dbWriteTable(con, "mtcars2", mtcars[0, ], temporary = TRUE)
dbReadTable(con, "mtcars2")

dbDisconnect(con)
} # }
```
