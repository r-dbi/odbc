test_that("databricks arguments use camelcase", {
  withr::local_envvar(DATABRICKS_TOKEN = "", DATABRICKS_AUTH_TYPE = "")

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
    DATABRICKS_AUTH_TYPE = "",
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

test_that("we hint viewer-based and service principal credentials on Connect", {
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

test_that("supports workload identity env-oidc with default token env var", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "my-sp",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN = "my-jwt",
    DATABRICKS_OIDC_TOKEN_ENV = ""
  )
  local_mocked_bindings(
    databricks_token_exchange = function(host, id_token, client_id) {
      expect_equal(id_token, "my-jwt")
      expect_equal(client_id, "my-sp")
      "exchanged-access-token"
    }
  )
  auth <- databricks_auth_args("my.cloud.databricks.com")
  expect_equal(auth$authMech, 11)
  expect_equal(auth$auth_flow, 0)
  expect_equal(auth$auth_accesstoken, "exchanged-access-token")
})

test_that("supports workload identity env-oidc with custom token env var name", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN_ENV = "MY_CUSTOM_JWT_VAR",
    MY_CUSTOM_JWT_VAR = "custom-jwt"
  )
  local_mocked_bindings(
    databricks_token_exchange = function(host, id_token, client_id) {
      expect_equal(id_token, "custom-jwt")
      "token"
    }
  )
  auth <- databricks_auth_args("host")
  expect_equal(auth$auth_accesstoken, "token")
})

test_that("workload identity env-oidc falls back when OIDC_TOKEN_ENV is empty", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN_ENV = "",
    DATABRICKS_OIDC_TOKEN = "fallback-jwt"
  )
  local_mocked_bindings(
    databricks_token_exchange = function(host, id_token, client_id) {
      expect_equal(id_token, "fallback-jwt")
      "token"
    }
  )
  auth <- databricks_auth_args("host")
  expect_equal(auth$auth_accesstoken, "token")
})

test_that("supports workload identity file-oidc", {
  token_file <- withr::local_tempfile()
  writeLines("file-jwt", token_file)
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "file-oidc",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = "",
    DATABRICKS_OIDC_TOKEN_FILEPATH = token_file
  )
  local_mocked_bindings(
    databricks_token_exchange = function(host, id_token, client_id) {
      expect_equal(id_token, "file-jwt")
      "exchanged-token"
    }
  )
  auth <- databricks_auth_args("host")
  expect_equal(auth$auth_accesstoken, "exchanged-token")
})

test_that("workload identity errors when DATABRICKS_CLIENT_ID is not set", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN = "jwt"
  )
  expect_snapshot(databricks_auth_args("host"), error = TRUE)
})

test_that("workload identity env-oidc errors when JWT env var is empty", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = ""
  )
  expect_snapshot(databricks_auth_args("host"), error = TRUE)
})

test_that("workload identity file-oidc errors when filepath is not set", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "file-oidc",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = "",
    DATABRICKS_OIDC_TOKEN_FILEPATH = ""
  )
  expect_snapshot(databricks_auth_args("host"), error = TRUE)
})

test_that("workload identity file-oidc errors when file does not exist", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "file-oidc",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = "",
    DATABRICKS_OIDC_TOKEN_FILEPATH = "/nonexistent/path/to/jwt"
  )
  expect_snapshot(databricks_auth_args("host"), error = TRUE)
})

test_that("workload identity file-oidc errors when file is empty", {
  token_file <- withr::local_tempfile()
  writeLines("", token_file)
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "file-oidc",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = "",
    DATABRICKS_OIDC_TOKEN_FILEPATH = token_file
  )
  expect_snapshot(
    databricks_auth_args("host"),
    error = TRUE,
    transform = function(x) gsub(token_file, "<tempfile>", x, fixed = TRUE)
  )
})

test_that("DATABRICKS_TOKEN takes precedence over workload identity", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "my-pat",
    DATABRICKS_CLIENT_ID = "sp",
    DATABRICKS_AUTH_TYPE = "env-oidc",
    DATABRICKS_OIDC_TOKEN = "my-jwt",
    DATABRICKS_OIDC_TOKEN_ENV = ""
  )
  auth <- databricks_auth_args("host")
  expect_equal(auth$pwd, "my-pat")
  expect_equal(auth$authMech, 3)
})

test_that("databricks_token_exchange extracts access_token from response", {
  skip_if_not_installed("httr2")
  httr2::local_mocked_responses(function(req) {
    httr2::response(
      status_code = 200L,
      headers = list(`content-type` = "application/json"),
      body = charToRaw(
        '{"access_token":"tok123","token_type":"Bearer","expires_in":3600}'
      )
    )
  })
  result <- databricks_token_exchange("host.example.com", "jwt", "sp-id")
  expect_equal(result, "tok123")
})

test_that("databricks_token_exchange errors on HTTP failure", {
  skip_if_not_installed("httr2")
  httr2::local_mocked_responses(function(req) {
    httr2::response(
      status_code = 400L,
      headers = list(`content-type` = "application/json"),
      body = charToRaw('{"error":"invalid_grant"}')
    )
  })
  expect_snapshot(
    databricks_token_exchange("host.example.com", "bad-jwt", "sp-id"),
    error = TRUE
  )
})

test_that("databricks_token_exchange errors when access_token is missing", {
  skip_if_not_installed("httr2")
  httr2::local_mocked_responses(function(req) {
    httr2::response(
      status_code = 200L,
      headers = list(`content-type` = "application/json"),
      body = charToRaw('{"token_type":"Bearer"}')
    )
  })
  expect_snapshot(
    databricks_token_exchange("host.example.com", "jwt", "sp-id"),
    error = TRUE
  )
})

test_that("DATABRICKS_CLIENT_ID still triggers M2M when AUTH_TYPE is not workload identity", {
  withr::local_envvar(
    DATABRICKS_TOKEN = "",
    DATABRICKS_CLIENT_ID = "abc",
    DATABRICKS_CLIENT_SECRET = "def",
    DATABRICKS_AUTH_TYPE = "",
    DATABRICKS_OIDC_TOKEN = "",
    DATABRICKS_OIDC_TOKEN_ENV = ""
  )
  auth <- databricks_auth_args("host")
  expect_equal(auth$auth_client_id, "abc")
  expect_equal(auth$auth_client_secret, "def")
  expect_equal(auth$auth_flow, 1)
})
