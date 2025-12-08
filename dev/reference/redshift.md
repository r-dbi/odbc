# Helper for Connecting to Redshift via ODBC

Connect to Redshift clusters via ODBC.

In particular, the custom
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
method for Redshift ODBC drivers automatically determines whether
IAM-based credentials are available, much like other AWS SDKs and tools.
This requires the paws.common package.

## Usage

``` r
redshift()

# S4 method for class 'RedshiftOdbcDriver'
dbConnect(
  drv,
  clusterId,
  server,
  database,
  region = NULL,
  driver = NULL,
  uid = NULL,
  pwd = NULL,
  dbUser = uid,
  ...
)
```

## Arguments

- drv:

  an object that inherits from
  [DBI::DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html),
  or an existing
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object (in order to clone an existing connection).

- clusterId:

  The Redshift cluster identifier. Only one of `clusterId` or the more
  verbose `server` is required.

- server:

  The full hostname of the Redshift cluster.

- database:

  The name of the Redshift database to connect to.

- region:

  The AWS region the Redshift cluster runs in. Ignored when `server` is
  provided. Defaults to the value of the environment variable
  `AWS_REGION`, then `AWS_REGION`, or uses `us-east-1` if both are
  unset.

- driver:

  The name of or path to a Redshift ODBC driver, or `NULL` to locate one
  automatically.

- uid, pwd:

  Disable IAM credentials and manually specify a username and password
  for authentication.

- dbUser:

  The Redshift database account.

- ...:

  Further arguments passed on to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## Value

An `OdbcConnection` object with an active connection to a Redshift
cluster or SQL warehouse.

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect to Redshift using IAM credentials.
DBI::dbConnect(
  odbc::redshift(),
  clusterId = "my-testing-cluster",
  database = "dev",
  dbUser = "me"
)
} # }
```
