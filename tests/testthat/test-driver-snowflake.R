test_that("can connect to snowflake", {
  key_exists <- Sys.getenv("SNOWFLAKE_PRIVATE_KEY_EXISTS")
  if (nchar(key_exists) == 0) {
    skip("Secret SNOWFLAKE_PRIVATE_KEY not available.")
  }

  con <- test_con("SNOWFLAKE")
})

test_that("an account ID is required", {
  withr::local_envvar(SNOWFLAKE_ACCOUNT = "")
  expect_snapshot(snowflake_args(driver = "driver"), error = TRUE)
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
    SNOWFLAKE_HOME = sf_home
  )
  args <- snowflake_args(driver = "driver")
  expect_equal(args$token, "token")
  expect_equal(args$authenticator, "oauth")
})

test_that("Workbench-managed credentials are ignored for other accounts", {
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
    SF_PARTNER = "test_partner"
  )
  expect_snapshot(
    snowflake_args(account = "testorg-test_account", driver = "driver"),
    error = TRUE
  )
})
