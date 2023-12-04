test_that("databricks arguments use camelcase", {
  withr::local_envvar(DATABRICKS_TOKEN = "")

  args <- databricks_args("foo", "bar", pwd = "pwd", uid = "user")
  expect_true(all(is_camel_case(names(args))))
})

test_that("errors if can't find driver", {
  local_mocked_bindings(
    file.exists = function(x, ...) rep(FALSE, length(x)),
    odbcListDrivers = function() list()
  )
  expect_snapshot(databricks_default_driver(), error = TRUE)
})

test_that("databricks host validates inputs", {
  expect_equal(databricks_host("https://my-host.com"), "my-host.com")
  expect_snapshot(databricks_host(""), error = TRUE)
})

test_that("user agent respects envvar", {
  local_mocked_bindings(packageVersion = function(...) "1.0.0")
  expect_equal(databricks_user_agent(), "r-odbc/1.0.0")

  withr::local_envvar(SPARK_CONNECT_USER_AGENT = "my-odbc/1.0.0")
  expect_equal(databricks_user_agent(), "my-odbc/1.0.0")
})

test_that("warns if auth fails", {
  withr::local_envvar(DATABRICKS_TOKEN = "")

  expect_snapshot(. <- databricks_args("path", "host"))

  expect_silent(databricks_args("path", "host", uid = "uid", pwd = "pwd"))
  expect_silent(databricks_args("path", "host", authMech = 10))
})

test_that("supports PAT in env var", {
  withr::local_envvar(DATABRICKS_TOKEN = "abc")
  expect_equal(databricks_auth_args()$pwd, "abc")
})

test_that("supports OAuth M2M in env var", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "abc",
    DATABRICKS_CLIENT_SECRET = "def"
  )

  auth <- databricks_auth_args()
  expect_equal(auth$auth_client_id, "abc")
  expect_equal(auth$auth_client_secret, "def")
})
