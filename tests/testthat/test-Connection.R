test_that("warn about case-insensitve arguments", {
  expect_no_error(check_args(list()))
  expect_no_error(check_args(list(x = 1, y = 1)))

  expect_snapshot(error = TRUE, {
    check_args(list(xa = 1, xA = 1))
    check_args(list(xa = 1, xA = 1, XA = 1))
    check_args(list(xa = 1, xA = 1, xb = 1, xB = 1))
  })
})

test_that("build_connection_string handles simple inputs", {
  expect_equal(build_connection_string(list()), "")
  expect_equal(build_connection_string(list(foo = "1")), "foo=1")
  expect_equal(build_connection_string(list(foo = "1", bar = "2")), "foo=1;bar=2")
})

test_that("build_connection_string automatically escapes if needed", {
  expect_equal(build_connection_string(list(foo = "*")), "foo={*}")
  # Already wrapped
  expect_equal(build_connection_string(list(foo = "{*}")), "foo={*}")
  # Respects AsIs
  expect_equal(build_connection_string(list(foo = I("*"))), "foo=*")
})

test_that("odbcListConfig returns appropriate result", {
  skip_on_os(c("windows", "solaris"))
  skip_if(!has_odbc(), "odbcinst not available.")

  res <- odbcListConfig()

  expect_type(res, "character")
  expect_length(res, 3)
  expect_named(res, c("drivers", "system_dsn", "user_dsn"))
  expect_match(res, "\\.ini")
})

test_that("odbcListConfig returns an empty vector on Windows", {
  skip_on_os(c("mac", "linux", "solaris"))

  res <- odbcListConfig()

  expect_equal(res, character(0))
})

test_that("odbcListConfig errors informatively without unixODBC", {
  skip_on_os(c("windows", "solaris"))
  skip_if(has_odbc(), "odbcinst is available.")

  expect_error(
    odbcListConfig(),
    "driver manager is not available"
  )
})

test_that("odbcListConfig errors informatively without unixODBC (mocked)", {
  local_mocked_bindings(
    has_odbc = function() {FALSE}
  )

  expect_snapshot(
    error = TRUE,
    odbcListConfig()
  )
})

test_that("odbcListConfig errors informatively with unexpected odbcinst output", {
  local_mocked_bindings(
    system = function(...) {c("beep", "bop")}
  )

  expect_snapshot(
    error = TRUE,
    odbcListConfig()
  )

  local_mocked_bindings(
    system = function(...) {""}
  )

  expect_snapshot(
    error = TRUE,
    odbcListConfig()
  )
})


