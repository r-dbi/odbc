# an account ID is required

    Code
      snowflake_args(driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Default connection "default" cannot be found.
      i No connections defined in configuration files.

# both 'uid' and 'pwd' are required when present

    Code
      snowflake_args(account = "testorg-test_account", driver = "driver", uid = "uid",
        )
    Condition
      Error in `DBI::dbConnect()`:
      ! Both `uid` and `pwd` must be specified to authenticate.
      i Or leave both unset to use ambient Snowflake credentials.

# we error if we can't find ambient credentials

    Code
      snowflake_args(account = "testorg-test_account", driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to detect ambient Snowflake credentials.
      i Supply `uid` and `pwd` to authenticate manually.

# we hint viewer-based credentials on Connect

    Code
      snowflake_args(account = "testorg-test_account", driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to detect ambient Snowflake credentials.
      i Supply `uid` and `pwd` to authenticate manually.
      i Or consider enabling Posit Connect's Snowflake integration for viewer-based credentials. See <https://docs.posit.co/connect/user/oauth-integrations/#adding-oauth-integrations-to-deployed-content> for details.

# we error if we can't find the driver

    Code
      snowflake_default_driver()
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to automatically find the Snowflake ODBC driver.
      i Set `driver` to known driver name or path.

# Workbench-managed credentials are ignored for other accounts

    Code
      snowflake_args(account = "testorg-test_account", driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to detect ambient Snowflake credentials.
      i Supply `uid` and `pwd` to authenticate manually.

# Invalid connection_name errors with known names

    Code
      snowflake_args(connection_name = "staging", driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Invalid `connection_name` "staging".
      i Known connections: "prod" and "dev".

# Missing default connection errors with known names

    Code
      snowflake_args(driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Default connection "default" cannot be found.
      i Known connection: "prod".

