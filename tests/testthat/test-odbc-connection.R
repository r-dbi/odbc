
# build_connection_string -------------------------------------------------

test_that("handles simple inputs", {
  expect_equal(build_connection_string(), "")
  expect_equal(build_connection_string(foo = "1"), "foo=1")
  expect_equal(build_connection_string(foo = "1", bar = "2"), "foo=1;bar=2")
})

test_that("escapes if needed", {
  expect_equal(build_connection_string(foo = "*"), "foo={*}")
  # Already wrapped
  expect_equal(build_connection_string(foo = "{*}"), "foo={*}")
  # Respects AsIs
  expect_equal(build_connection_string(foo = I("*")), "foo=*")
})

test_that("combines with existing .connection string", {
  expect_equal(build_connection_string("x=1"), "x=1")
  expect_equal(build_connection_string("x=1", foo = "1"), "x=1;foo=1")
  expect_equal(build_connection_string("x=1;", foo = "1"), "x=1;foo=1")
})

test_that("errors if unnamed arguments", {
  expect_snapshot(build_connection_string(1, 2, 3), error = TRUE)
})

test_that("errors about case-insensitve arguments", {
  expect_no_error(build_connection_string())
  expect_no_error(build_connection_string(x = 1, y = 1))

  expect_snapshot(error = TRUE, {
    build_connection_string(xa = 1, xA = 1)
    build_connection_string(xa = 1, xA = 1, XA = 1)
    build_connection_string(xa = 1, xA = 1, xb = 1, xB = 1)
  })
})

# odbcConnectionColumns deprecation --------------------------------------

test_that("odbcConnectionColumns warns on usage (#699)", {
  con <- test_con("SQLITE")
  expect_deprecated(odbcConnectionColumns(con, "test"))
})

test_that("odbcConnectionColumns_ is eventually removed (#699)", {
  skip_on_cran()
  if (Sys.Date() > "2026-01-01") {
    testthat::expect(
      FALSE,
      c("Time to unexport `odbcConnectionColumns()` and rename",
        "`odbcConnectionColumns_()` to `odbcConnectionColumns()`! See #699.")
    )
  }
})
