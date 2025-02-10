test_that("databricks arguments use camelcase", {
  withr::local_envvar(DATABRICKS_TOKEN = "")

  args <- databricks_args(
    "foo",
    "bar",
    pwd = "pwd",
    uid = "user",
    driver = "driver"
  )
  expect_true(all(is_camel_case(names(args))))
})

test_that("manually supplied arguments override automatic", {
  withr::local_envvar(DATABRICKS_TOKEN = "abc")
  args <- databricks_args("x", "y", driver = "driver")
  expect_equal(args$authMech, 3)

  args <- databricks_args("x", "y", driver = "driver", authMech = 123)
  expect_equal(args$authMech, 123)
})

test_that("fallbacks to driver name", {
  local_mocked_bindings(
    databricks_default_driver_paths = function() character(),
    odbcListDrivers = function() list(name = c("bar", "Databricks"))
  )
  expect_equal(databricks_default_driver(), "Databricks")
})

test_that("errors if can't find driver", {
  local_mocked_bindings(
    databricks_default_driver_paths = function() character(),
    odbcListDrivers = function() list()
  )
  expect_snapshot(databricks_default_driver(), error = TRUE)
})

test_that("databricks host validates inputs", {
  expect_equal(databricks_host("https://my-host.com"), "my-host.com")
  expect_equal(databricks_host("https://my-host.com/"), "my-host.com")
  expect_equal(databricks_host("my-host.com/"), "my-host.com")
  expect_snapshot(databricks_host(""), error = TRUE)
})

test_that("user agent respects envvar", {
  withr::local_envvar(SPARK_CONNECT_USER_AGENT = NULL)
  local_mocked_bindings(packageVersion = function(...) "1.0.0")
  expect_equal(databricks_user_agent(), "r-odbc/1.0.0")

  withr::local_envvar(SPARK_CONNECT_USER_AGENT = "my-odbc/1.0.0")
  expect_equal(databricks_user_agent(), "my-odbc/1.0.0")
})

test_that("errors if auth fails", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CONFIG_FILE = NULL
  )

  databricks_args1 <- function(...) {
    databricks_args("path", "host", driver = "driver", ...)
  }

  expect_snapshot(. <- databricks_args1(), error = TRUE)

  expect_silent(databricks_args1(uid = "uid", pwd = "pwd"))
  expect_silent(databricks_args1(authMech = 10))
})

test_that("uid and pwd suppress automated auth", {
  auth <- databricks_auth_args("host", uid = "uid", pwd = "pwd")
  expect_equal(auth, list(uid = "uid", pwd = "pwd", authMech = 3))
})

test_that("must supply both uid and pwd", {
  expect_snapshot(databricks_auth_args("host", uid = "uid"), error = TRUE)
})

test_that("supports PAT in env var", {
  withr::local_envvar(DATABRICKS_TOKEN = "abc")
  expect_equal(databricks_auth_args("host")$pwd, "abc")
})

test_that("supports OAuth M2M in env var", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "abc",
    DATABRICKS_CLIENT_SECRET = "def"
  )

  auth <- databricks_auth_args("host")
  expect_equal(auth$auth_client_id, "abc")
  expect_equal(auth$auth_client_secret, "def")
})

test_that("dbConnect method handles httpPath aliases (#787)", {
  local_mocked_bindings(
    databricks_args = function(...) stop("made it"),
    configure_simba = function(...) TRUE
  )

  expect_error(dbConnect(databricks(), HTTPPath = "boop"), "made it")
  expect_error(dbConnect(databricks(), httpPath = "boop"), "made it")
})

test_that("dbConnect method errors informatively re: httpPath (#787)", {
  local_mocked_bindings(configure_simba = function(...) TRUE)

  expect_snapshot(
    error = TRUE,
    dbConnect(databricks(), httpPath = "boop", HTTPPath = "bop")
  )

  expect_snapshot(error = TRUE, dbConnect(databricks(), HTTPPath = 1L))
  expect_snapshot(error = TRUE, dbConnect(databricks(), httpPath = 1L))
})

test_that("Workbench-managed credentials are detected correctly", {
  # Emulate the databricks.cfg file written by Workbench.
  db_home <- tempfile("posit-workbench")
  dir.create(db_home)
  writeLines(
    c(
      '[workbench]',
      'host = some-host',
      'token = token'
    ),
    file.path(db_home, "databricks.cfg")
  )
  withr::local_envvar(
    DATABRICKS_CONFIG_FILE = file.path(db_home, "databricks.cfg")
  )
  args <- databricks_auth_args(host = "some-host")
  expect_equal(args, list(authMech = 11, auth_flow = 0, auth_accesstoken = "token"))
})

test_that("Workbench-managed credentials are ignored for other hosts", {
  # Emulate the databricks.cfg file written by Workbench.
  db_home <- tempfile("posit-workbench")
  dir.create(db_home)
  writeLines(
    c(
      '[workbench]',
      'host = nonmatching',
      'token = token'
    ),
    file.path(db_home, "databricks.cfg")
  )
  withr::local_envvar(
    DATABRICKS_CONFIG_FILE = file.path(db_home, "databricks.cfg")
  )
  expect_equal(databricks_auth_args(host = "some-host"), NULL)
})

test_that("we hint viewer-based credentials on Connect", {
  local_mocked_bindings(
    running_on_connect = function() TRUE
  )
  expect_snapshot(
    databricks_args(
      workspace = "workspace",
      httpPath = "path",
      driver = "driver"
    ),
    error = TRUE
  )
})

test_that("tokens can be requested from a Connect server", {
  skip_if_not_installed("connectcreds")

  connectcreds::local_mocked_connect_responses(token = "token")
  expect_equal(
    databricks_auth_args("example.cloud.databricks.com"),
    list(authMech = 11, auth_flow = 0, auth_accesstoken = "token")
  )
})
