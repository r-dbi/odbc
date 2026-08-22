test_that("can connect to snowflake", {
  key_exists <- Sys.getenv("SNOWFLAKE_PRIVATE_KEY_EXISTS")
  if (nchar(key_exists) == 0) {
    skip("Secret SNOWFLAKE_PRIVATE_KEY not available.")
  }

  con <- test_con("SNOWFLAKE")
})

test_that("an account ID is required", {
  sf_home <- tempfile()
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "",
    SNOWFLAKE_HOME = sf_home
  )
  expect_snapshot(
    snowflake_args(driver = "driver"),
    error = TRUE,
    transform = function(x) gsub(sf_home, "<tmp>", x, fixed = TRUE)
  )
})

test_that("environment variables are handled correctly", {
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SF_PARTNER = "test_partner"
  )
  args <- snowflake_args(
    pwd = "pwd",
    uid = "user",
    driver = "driver"
  )
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
  expect_equal(args$application, "test_partner")
})

test_that("environment variables can be overridden with parameters", {
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "account",
    SF_PARTNER = "test_partner"
  )
  args <- snowflake_args(
    account = "testorg-test_account",
    pwd = "pwd",
    uid = "user",
    driver = "driver",
    application = "myapp"
  )
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
  expect_equal(args$application, "myapp")
})

test_that("the 'uid' and 'pwd' arguments suppress automated auth", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    uid = "uid",
    pwd = "pwd"
  )
  expect_equal(args$uid, "uid")
  expect_equal(args$pwd, "pwd")
  expect_equal(args$authenticator, NULL)
})

test_that("both 'uid' and 'pwd' are required when present", {
  expect_snapshot(
    snowflake_args(
      account = "testorg-test_account",
      driver = "driver",
      uid = "uid",
    ),
    error = TRUE
  )
})

test_that("alternative authenticators are supported", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "externalbrowser"
  )
  expect_equal(args$authenticator, "externalbrowser")
})

test_that("can pass only `uid` with non-NULL `authenticator` (#817, #889)", {
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "externalbrowser",
    uid = "boop"
  )
  expect_equal(args$uid, "boop")
  expect_equal(args$authenticator, "externalbrowser")

  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    authenticator = "SNOWFLAKE_JWT",
    uid = "boop"
  )
  expect_equal(args$uid, "boop")
  expect_equal(args$authenticator, "SNOWFLAKE_JWT")
})

test_that("we error if we can't find ambient credentials", {
  withr::local_envvar(SF_PARTNER = "")
  local_mocked_bindings(
    snowflake_auth_args = function(...) list()
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

test_that("we hint viewer-based credentials on Connect", {
  withr::local_envvar(SF_PARTNER = "")
  local_mocked_bindings(
    snowflake_auth_args = function(...) list(),
    running_on_connect = function() TRUE
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

test_that("tokens can be requested from a Connect server", {
  skip_if_not_installed("connectcreds")

  connectcreds::local_mocked_connect_responses(token = "token")
  expect_equal(
    snowflake_auth_args("testorg-test_account"),
    list(authenticator = "oauth", token = "token")
  )
})

test_that("the default driver falls back to a known driver name", {
  local_mocked_bindings(
    snowflake_default_driver_paths = function() character(),
    odbcListDrivers = function() list(name = c("bar", "Snowflake"))
  )
  expect_equal(snowflake_default_driver(), "Snowflake")
})

test_that("we error if we can't find the driver", {
  local_mocked_bindings(
    snowflake_default_driver_paths = function() character(),
    odbcListDrivers = function() list()
  )
  expect_snapshot(snowflake_default_driver(), error = TRUE)
})

test_that("Workbench-managed credentials are detected correctly", {
  # Emulate the connections.toml file written by Workbench.
  sf_home <- tempfile("posit-workbench")
  dir.create(sf_home)
  writeLines(
    c(
      '[workbench]',
      'account = "testorg-test_account"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SNOWFLAKE_DEFAULT_CONNECTION_NAME = "workbench",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver")
  expect_equal(args$token, "token")
  expect_equal(args$authenticator, "oauth")
})

test_that("Workbench-managed credentials are rejected for other accounts", {
  # Emulate the connections.toml file written by Workbench.
  sf_home <- tempfile("posit-workbench")
  dir.create(sf_home)
  writeLines(
    c(
      '[workbench]',
      'account = "nonmatching"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_HOME = sf_home,
    SNOWFLAKE_DEFAULT_CONNECTION_NAME = "workbench",
    SF_PARTNER = "test_partner"
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})

test_that("snowflake_connection_to_odbc_args maps fields correctly", {
  conn <- structure(
    list(
      name = "test",
      account = "testorg-test_account",
      user = "myuser",
      authenticator = "oauth",
      token = structure("mytoken", class = c("snowflake_redacted", "character")),
      warehouse = "mywh",
      database = "mydb",
      schema = "myschema",
      role = "myrole"
    ),
    class = c("snowflake_connection", "list")
  )
  args <- snowflake_connection_to_odbc_args(conn)
  expect_equal(args$uid, "myuser")
  expect_equal(args$token, "mytoken")
  expect_false(inherits(args$token, "snowflake_redacted"))
  expect_equal(args$authenticator, "oauth")
  expect_equal(args$warehouse, "mywh")
  expect_equal(args$database, "mydb")
  expect_equal(args$schema, "myschema")
  expect_equal(args$role, "myrole")
  expect_null(args$account)
  expect_null(args$name)
})

test_that("snowflake_connection_to_odbc_args maps private key fields", {
  conn <- structure(
    list(
      name = "test",
      account = "testorg-test_account",
      user = "myuser",
      authenticator = "SNOWFLAKE_JWT",
      private_key_file = "/path/to/rsa_key.p8",
      private_key_file_pwd = structure("secret", class = c("snowflake_redacted", "character"))
    ),
    class = c("snowflake_connection", "list")
  )
  args <- snowflake_connection_to_odbc_args(conn)
  expect_equal(args$priv_key_file, "/path/to/rsa_key.p8")
  expect_equal(args$priv_key_file_pwd, "secret")
  expect_false(inherits(args$priv_key_file_pwd, "snowflake_redacted"))
  expect_equal(args$authenticator, "SNOWFLAKE_JWT")
})

test_that("snowflake_connection_to_odbc_args omits default authenticator", {
  conn <- structure(
    list(
      name = "test",
      account = "testorg-test_account",
      user = "myuser",
      password = structure("mypwd", class = c("snowflake_redacted", "character")),
      authenticator = "snowflake"
    ),
    class = c("snowflake_connection", "list")
  )
  args <- snowflake_connection_to_odbc_args(conn)
  expect_null(args$authenticator)
  expect_equal(args$uid, "myuser")
  expect_equal(args$pwd, "mypwd")
  expect_false(inherits(args$pwd, "snowflake_redacted"))
})

test_that("snowflake_connection_to_odbc_args passes through token_file_path", {
  conn <- structure(
    list(
      name = "test",
      account = "testorg-test_account",
      authenticator = "oauth",
      token_file_path = "/snowflake/session/token"
    ),
    class = c("snowflake_connection", "list")
  )
  args <- snowflake_connection_to_odbc_args(conn)
  expect_equal(args$token_file_path, "/snowflake/session/token")
  expect_equal(args$authenticator, "oauth")
})

test_that("host field overrides server in snowflake_args", {
  sf_home <- tempfile("snowflake-host-test")
  dir.create(sf_home)
  writeLines(
    c(
      '[default]',
      'account = "testorg-test_account"',
      'host = "custom.snowflake.example.com"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver")
  expect_equal(args$server, "custom.snowflake.example.com")
})

test_that("snowflake_server uses host when provided", {
  expect_equal(
    snowflake_server("testorg-test_account", host = "custom.example.com"),
    "custom.example.com"
  )
  expect_equal(
    snowflake_server("testorg-test_account", host = NULL),
    "testorg-test_account.snowflakecomputing.com"
  )
  expect_equal(
    snowflake_server("testorg-test_account", host = ""),
    "testorg-test_account.snowflakecomputing.com"
  )
})

test_that("explicit account works without connections.toml", {
  sf_home <- tempfile()
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(
    account = "testorg-test_account",
    driver = "driver",
    uid = "user",
    pwd = "pwd"
  )
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
})

test_that("connection_name selects a named connection", {
  sf_home <- tempfile("snowflake-named")
  dir.create(sf_home)
  writeLines(
    c(
      '[default]',
      'account = "default-account"',
      'token = "default-token"',
      'authenticator = "oauth"',
      '',
      '[production]',
      'account = "prod-account"',
      'token = "prod-token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver", connection_name = "production")
  expect_equal(args$account, "prod-account")
  expect_equal(args$token, "prod-token")
  expect_equal(args$server, "prod-account.snowflakecomputing.com")
  expect_null(args$connection_name)
})

test_that("account is resolved from connections.toml when SNOWFLAKE_ACCOUNT is unset", {
  sf_home <- tempfile("snowflake-no-account")
  dir.create(sf_home)
  writeLines(
    c(
      '[default]',
      'account = "testorg-test_account"',
      'token = "token"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver")
  expect_equal(args$account, "testorg-test_account")
  expect_equal(args$server, "testorg-test_account.snowflakecomputing.com")
  expect_equal(args$token, "token")
})

test_that("NULL caller args don't clobber config-resolved values", {
  sf_home <- tempfile("snowflake-null-args")
  dir.create(sf_home)
  writeLines(
    c(
      '[default]',
      'account = "testorg-test_account"',
      'user = "me@example.com"',
      'authenticator = "externalbrowser"',
      'warehouse = "mywh"',
      'database = "mydb"',
      'schema = "myschema"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(
    driver = "driver",
    uid = NULL,
    pwd = NULL,
    warehouse = NULL,
    database = NULL,
    schema = NULL
  )
  expect_equal(args$uid, "me@example.com")
  expect_equal(args$authenticator, "externalbrowser")
  expect_equal(args$warehouse, "mywh")
  expect_equal(args$database, "mydb")
  expect_equal(args$schema, "myschema")
})

test_that("connection_name bypasses account mismatch check", {
  sf_home <- tempfile("snowflake-bypass")
  dir.create(sf_home)
  writeLines(
    c(
      '[myconn]',
      'account = "other-account"',
      'token = "tok"',
      'authenticator = "oauth"'
    ),
    file.path(sf_home, "connections.toml")
  )
  withr::local_envvar(
    SNOWFLAKE_ACCOUNT = "testorg-test_account",
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver", connection_name = "myconn")
  expect_equal(args$account, "other-account")
  expect_equal(args$token, "tok")
  expect_equal(args$server, "other-account.snowflakecomputing.com")
})

test_that("workload_identity params are passed through", {
  conn <- structure(
    list(
      name = "test",
      account = "testorg-test_account",
      authenticator = "workload_identity",
      workload_identity_provider = "OIDC",
      token_file_path = "/var/run/secrets/token"
    ),
    class = c("snowflake_connection", "list")
  )
  args <- snowflake_connection_to_odbc_args(conn)
  expect_equal(args$authenticator, "workload_identity")
  expect_equal(args$workload_identity_provider, "OIDC")
  expect_equal(args$token_file_path, "/var/run/secrets/token")
})
