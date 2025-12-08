# Set the Transaction Isolation Level for a Connection

Set the Transaction Isolation Level for a Connection

## Usage

``` r
odbcSetTransactionIsolationLevel(conn, levels)
```

## Arguments

- conn:

  A
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object, as returned by
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

- levels:

  One or more of 'read_uncommitted', 'read_committed',
  'repeatable_read', 'serializable'.

## See also

<https://learn.microsoft.com/en-us/sql/odbc/reference/develop-app/setting-the-transaction-isolation-level>

## Examples

``` r
if (FALSE) { # \dontrun{
# Can use spaces or underscores in between words.
odbcSetTransactionIsolationLevel(con, "read uncommitted")

# Can also use the full constant name.
odbcSetTransactionIsolationLevel(con, "SQL_TXN_READ_UNCOMMITTED")
} # }
```
