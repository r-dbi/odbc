# Helper for connecting to Snowflake via ODBC

Connect to a Snowflake account via the [Snowflake ODBC
driver](https://docs.snowflake.com/en/developer-guide/odbc/odbc).

In particular, the custom
[`dbConnect()`](https://odbc.r-dbi.org/reference/dbConnect-OdbcDriver-method.md)
method for the Snowflake ODBC driver supports the `connections.toml` and
`config.toml` files used by the Snowflake Connector for Python and the
Snowflake CLI via the snowflakeauth package. It also detects ambient
OAuth credentials on platforms like Snowpark Container Services or Posit
Workbench. Finally, it can detect viewer-based credentials on Posit
Connect if the connectcreds package is installed.

In addition, on macOS platforms, the `dbConnect` method will check and
warn if it detects irregularities with how the driver is configured,
unless the `odbc.no_config_override` environment variable is set.

## Usage

``` r
snowflake()

# S4 method for class 'SnowflakeOdbcDriver'
dbConnect(
  drv,
  account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
  driver = NULL,
  warehouse = NULL,
  database = NULL,
  schema = NULL,
  uid = NULL,
  pwd = NULL,
  connection_name = NULL,
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

- account:

  A Snowflake [account
  identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier),
  e.g. `"testorg-test_account"`.

- driver:

  The name of the Snowflake ODBC driver, or `NULL` to use the default
  name.

- warehouse:

  The name of a Snowflake compute warehouse, or `NULL` to use the
  default.

- database:

  The name of a Snowflake database, or `NULL` to use the default.

- schema:

  The name of a Snowflake database schema, or `NULL` to use the default.

- uid, pwd:

  Manually specify a username and password for authentication.
  Specifying these options will disable ambient credential discovery.

- connection_name:

  The name of a connection defined in your Snowflake `connections.toml`
  file, or `NULL` to use the default connection.

- ...:

  Further arguments passed on to
  [`dbConnect()`](https://odbc.r-dbi.org/reference/dbConnect-OdbcDriver-method.md).

## Value

An `OdbcConnection` object with an active connection to a Snowflake
account.

## Examples

``` r
if (FALSE) { # \dontrun{
# Use ambient credentials.
DBI::dbConnect(odbc::snowflake())

# Use browser-based SSO (if configured). Only works on desktop.
DBI::dbConnect(
  odbc::snowflake(),
  account = "testorg-test_account",
  authenticator = "externalbrowser"
)

# Use a traditional username & password.
DBI::dbConnect(
  odbc::snowflake(),
  account = "testorg-test_account",
  uid = "me",
  pwd = rstudioapi::askForPassword()
)

# Use a named connection from a connections.toml file.
DBI::dbConnect(odbc::snowflake(), connection_name = "test")

# Use credentials from the viewer (when possible) in a Shiny app
# deployed to Posit Connect.
library(connectcreds)
server <- function(input, output, session) {
  conn <- DBI::dbConnect(odbc::snowflake())
}
} # }
```
