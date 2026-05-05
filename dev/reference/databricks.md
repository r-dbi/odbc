# Helper for Connecting to Databricks via ODBC

Connect to Databricks clusters and SQL warehouses via the [Databricks
ODBC driver](https://www.databricks.com/spark/odbc-drivers-download).

In particular, the custom
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
method for the Databricks ODBC driver implements a variant of
Databricks's [unified
authentication](https://docs.databricks.com/aws/en/dev-tools/auth/unified-auth)
model when no `uid` or `pwd` is supplied, checking for ambient
credentials in the following order:

- Viewer-based or service principal credentials supplied by Posit
  Connect (requires the connectcreds package).

- Personal access tokens.

- Workload identity federation.

- OAuth machine-to-machine credentials.

- OAuth user-to-machine credentials suplied via Posit Workbench or the
  Databricks CLI on desktop.

This aims to provide broad compatibility between odbc and the standard
environment variables used by Databricks SDKs in R and other languages.

In addition, on macOS platforms, the
[`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md)
method will check for irregularities with how the driver is configured,
and attempt to fix in-situ, unless the `odbc.no_config_override`
environment variable is set.

## Usage

``` r
databricks()

# S4 method for class 'DatabricksOdbcDriver'
dbConnect(
  drv,
  httpPath,
  workspace = Sys.getenv("DATABRICKS_HOST"),
  useNativeQuery = TRUE,
  driver = NULL,
  HTTPPath,
  uid = NULL,
  pwd = NULL,
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

- httpPath, HTTPPath:

  To query a cluster, use the HTTP Path value found under
  `Advanced Options > JDBC/ODBC` in the Databricks UI. For SQL
  warehouses, this is found under `Connection Details` instead.

- workspace:

  The URL of a Databricks workspace, e.g.
  `"https://example.cloud.databricks.com"`.

- useNativeQuery:

  Suppress the driver's conversion from ANSI SQL 92 to HiveSQL? The
  default (`TRUE`), gives greater performance but means that
  paramterised queries (and hence
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html))
  do not work.

- driver:

  The name of the Databricks ODBC driver, or `NULL` to use the default
  name.

- uid, pwd:

  Manually specify a username and password for authentication.
  Specifying these options will disable automated credential discovery.

- ...:

  Further arguments passed on to
  [`dbConnect()`](https://odbc.r-dbi.org/dev/reference/dbConnect-OdbcDriver-method.md).

## Value

An `OdbcConnection` object with an active connection to a Databricks
cluster or SQL warehouse.

## Examples

``` r
if (FALSE) { # \dontrun{
DBI::dbConnect(
  odbc::databricks(),
  httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
)

# Use credentials from the viewer or a service principal (when possible) in
# a Shiny app deployed to Posit Connect.
library(connectcreds)
server <- function(input, output, session) {
  conn <- DBI::dbConnect(
    odbc::databricks(),
    workspace = "https://example.cloud.databricks.com",
    httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
  )
}
} # }
```
