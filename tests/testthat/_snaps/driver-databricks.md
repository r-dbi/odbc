# errors if can't find driver

    Code
      databricks_default_driver()
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to automatically find the Databricks/Spark ODBC driver.
      i Set `driver` to known driver name or path.

# databricks host validates inputs

    Code
      databricks_host("")
    Condition
      Error in `DBI::dbConnect()`:
      ! No Databricks workspace URL provided.
      i Either supply `workspace` argument or set env var `DATABRICKS_HOST`.

# errors if auth fails

    Code
      . <- databricks_args1()
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to detect ambient Databricks credentials.
      i Supply `uid` and `pwd` to authenticate manually.

# must supply both uid and pwd

    Code
      databricks_auth_args("host", uid = "uid")
    Condition
      Error in `DBI::dbConnect()`:
      ! Both `uid` and `pwd` must be specified for manual authentication.
      i Or leave both unset for automated authentication.

# dbConnect method errors informatively re: httpPath (#787)

    Code
      dbConnect(databricks(), httpPath = "boop", HTTPPath = "bop")
    Condition
      Error in `dbConnect()`:
      ! Exactly one of `httpPath` or `HTTPPath` must be supplied.

---

    Code
      dbConnect(databricks(), HTTPPath = 1L)
    Condition
      Error in `dbConnect()`:
      ! `HTTPPath` must be a single string or `NULL`, not the number 1.

---

    Code
      dbConnect(databricks(), httpPath = 1L)
    Condition
      Error in `dbConnect()`:
      ! `httpPath` must be a single string or `NULL`, not the number 1.

# we hint viewer-based and service principal credentials on Connect

    Code
      databricks_args(workspace = "workspace", httpPath = "path", driver = "driver")
    Condition
      Error in `DBI::dbConnect()`:
      ! Failed to detect ambient Databricks credentials.
      i Supply `uid` and `pwd` to authenticate manually.
      i Or consider enabling Posit Connect's Databricks integration.  For viewer-based credentials, see <https://docs.posit.co/connect/user/oauth-integrations/#viewer-oauth-integrations> for details.  For service principal credentials, see <https://docs.posit.co/connect/user/oauth-integrations/#service-account-oauth-integrations> for details.

# workload identity errors when DATABRICKS_CLIENT_ID is not set

    Code
      databricks_auth_args("host")
    Condition
      Error in `DBI::dbConnect()`:
      ! Workload identity federation requires a service principal.
      i Set the `DATABRICKS_CLIENT_ID` environment variable to the service principal's UUID.

# workload identity env-oidc errors when JWT env var is empty

    Code
      databricks_auth_args("host")
    Condition
      Error in `DBI::dbConnect()`:
      ! Workload identity federation is enabled (`DATABRICKS_AUTH_TYPE=env-oidc`) but no OIDC token was found.
      i Set the `DATABRICKS_OIDC_TOKEN` environment variable to the IdP JWT.

# workload identity file-oidc errors when filepath is not set

    Code
      databricks_auth_args("host")
    Condition
      Error in `DBI::dbConnect()`:
      ! Workload identity federation is enabled (`DATABRICKS_AUTH_TYPE=file-oidc`) but `DATABRICKS_OIDC_TOKEN_FILEPATH` is not set.
      i Set `DATABRICKS_OIDC_TOKEN_FILEPATH` to the path of the file containing the IdP JWT.

# workload identity file-oidc errors when file does not exist

    Code
      databricks_auth_args("host")
    Condition
      Error in `DBI::dbConnect()`:
      ! OIDC token file '/nonexistent/path/to/jwt' does not exist.
      i Verify `DATABRICKS_OIDC_TOKEN_FILEPATH` points to a readable file.

# workload identity file-oidc errors when file is empty

    Code
      databricks_auth_args("host")
    Condition
      Error in `DBI::dbConnect()`:
      ! OIDC token file '<tempfile>' is empty.

# databricks_token_exchange errors on HTTP failure

    Code
      databricks_token_exchange("host.example.com", "bad-jwt", "sp-id")
    Condition
      Error in `DBI::dbConnect()`:
      ! Databricks OIDC token exchange failed with HTTP 400.
      i Response: {"error":"invalid_grant"}

# databricks_token_exchange errors when access_token is missing

    Code
      databricks_token_exchange("host.example.com", "jwt", "sp-id")
    Condition
      Error in `DBI::dbConnect()`:
      ! Databricks OIDC token exchange response did not contain an access token.
      i Verify the federation policy is configured correctly in Databricks.

