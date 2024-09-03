test_that("odbcListConfig returns appropriate result", {
  skip_on_os(c("windows", "solaris"))
  skip_if(!has_unixodbc(), "odbcinst not available.")

  res <- odbcListConfig()

  expect_type(res, "character")
  expect_length(res, 3)
  expect_named(res, c("drivers", "system_dsn", "user_dsn"))
  expect_match(res, "\\.ini")
})

test_that("odbcListConfig returns an empty vector on Windows", {
  local_mocked_bindings(is_windows = function() {TRUE})

  res <- odbcListConfig()

  expect_equal(res, character(0))
})

test_that("odbcListConfig errors informatively without unixODBC", {
  local_mocked_bindings(is_windows = function() {FALSE},
                        has_unixodbc = function() {FALSE})

  expect_snapshot(error = TRUE, odbcListConfig())
})

test_that("odbcListConfig errors informatively with unexpected odbcinst output", {
  local_mocked_bindings(is_windows = function() {FALSE},
                        has_unixodbc = function() {TRUE})

  local_mocked_bindings(system = function(...) {c("beep", "bop")})
  expect_snapshot(error = TRUE, odbcListConfig())

  local_mocked_bindings(system = function(...) {""})
  expect_snapshot(error = TRUE, odbcListConfig())
})

test_that("odbcEdit*() errors informatively on Windows", {
  local_mocked_bindings(is_windows = function() {TRUE})

  expect_snapshot(error = TRUE, odbcEditDrivers())
})
