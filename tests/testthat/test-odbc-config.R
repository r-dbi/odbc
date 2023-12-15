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
  skip_on_os(c("windows", "solaris"))

  local_mocked_bindings(
    has_odbc = function() {FALSE}
  )

  expect_snapshot(
    error = TRUE,
    odbcListConfig()
  )
})

test_that("odbcListConfig errors informatively with unexpected odbcinst output", {
  skip_on_os(c("windows", "solaris"))

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
