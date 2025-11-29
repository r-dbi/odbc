# Return the corresponding ODBC data type for an R object

This is used when creating a new table with
[`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html).
Databases with default methods defined are:

- MySQL

- PostgreSQL

- SQL Server

- Oracle

- SQLite

- Spark

- Hive

- Impala

- Redshift

- Vertica

- BigQuery

- Teradata

- Access

- Snowflake

## Usage

``` r
odbcDataType(con, obj, ...)
```

## Arguments

- con:

  A driver connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- obj:

  An R object.

- ...:

  Additional arguments passed to methods.

## Value

Corresponding SQL type for the `obj`.

## Details

If you are using a different database and
[`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
fails with a SQL parsing error the default method is not appropriate,
you will need to write a new method. The object type for your method
will be the database name retrieved by `dbGetInfo(con)$dbms.name`. Use
the documentation provided with your database to determine appropriate
values for each R data type.
