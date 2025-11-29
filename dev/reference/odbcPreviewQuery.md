# Create a preview query.

Optimize against the rowLimit argument. S3 since some back-ends do not
parse the LIMIT syntax. Internal, not expected that users would interact
with this method.

## Usage

``` r
odbcPreviewQuery(connection, rowLimit, name)

# S3 method for class 'OdbcConnection'
odbcPreviewQuery(connection, rowLimit, name)

# S3 method for class '`Microsoft SQL Server`'
odbcPreviewQuery(connection, rowLimit, name)

# S3 method for class 'Teradata'
odbcPreviewQuery(connection, rowLimit, name)

# S3 method for class 'Oracle'
odbcPreviewQuery(connection, rowLimit, name)
```

## Arguments

- connection:

  A connection object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- rowLimit:

  The maximum number of rows to display.

- name:

  Name of the object to be previewed
