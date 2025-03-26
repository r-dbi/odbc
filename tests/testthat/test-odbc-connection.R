
# build_connection_string -------------------------------------------------

test_that("handles simple inputs", {
  expect_equal(build_connection_string(), "")
  expect_equal(build_connection_string(list(foo = "1")), "foo=1")
  expect_equal(build_connection_string(list(foo = "1", bar = "2")), "foo=1;bar=2")
})

test_that("combines with existing .connection string", {
  expect_equal(build_connection_string(string = "x=1"), "x=1")
  expect_equal(build_connection_string(list(foo = "1"), "x=1"), "x=1;foo=1")
  expect_equal(build_connection_string(list(foo = "1"), "x=1;"), "x=1;foo=1")
})

test_that("errors if unnamed arguments", {
  expect_snapshot(check_args(list(1, 2, 3)), error = TRUE)
})

test_that("errors about case-insensitve arguments", {
  expect_no_error(check_args(list()))
  expect_no_error(check_args(list(x = 1, y = 1)))

  expect_snapshot(error = TRUE, {
    check_args(list(xa = 1, xA = 1))
    check_args(list(xa = 1, xA = 1, XA = 1))
    check_args(list(xa = 1, xA = 1, xb = 1, xB = 1))
  })
})

test_that("messages if values might need quoting", {
  expect_snapshot(check_quoting(list(foo = "f{oo", bar = "b{ar", baz = "baz")))
})

test_that("correctly detects values that need escaping", {
  # I() opts-out
  expect_false(needs_quoting(I("f{o")))

  # already quoted
  expect_false(needs_quoting("'f{o'"))
  expect_false(needs_quoting('"f{o"'))
  expect_false(needs_quoting("{f{o}"))

  # no special values
  expect_false(needs_quoting("foo"))

  # has a special character
  expect_true(needs_quoting("foo{"))
  expect_true(needs_quoting("foo}"))
  expect_true(needs_quoting("foo="))
  expect_true(needs_quoting("foo;"))

  # space at start or end
  expect_true(needs_quoting("foo "))
  expect_true(needs_quoting(" foo"))
  expect_false(needs_quoting("fo o"))
})

test_that("automatically picks correct quote type", {
  expect_equal(quote_value("x"), I('"x"'))
  expect_equal(quote_value("x'"), I('"x\'"'))
  expect_equal(quote_value("x'"), I('"x\'"'))

  expect_snapshot(quote_value("'\""), error = TRUE)
})

# connections pane -------------------------------------------------------------
test_that("validateObjectName() errors informatively", {
  skip_if_no_unixodbc()
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    odbcListColumns(con, table = "boop", view = "bop")
  )

  expect_snapshot(
    error = TRUE,
    odbcListColumns(con)
  )
})

# odbcConnectionColumns deprecation --------------------------------------

test_that("odbcConnectionColumns warns on usage (#699)", {
  skip_if_no_unixodbc()
  con <- test_con("SQLITE")
  lifecycle::expect_deprecated(odbcConnectionColumns(con, "test"))
})

test_that("odbcConnectionColumns_ is eventually removed (#699)", {
  skip_on_cran()
  if (Sys.Date() > "2026-01-01") {
    testthat::expect(
      FALSE,
      c("Time to unexport deprecated `odbcConnection*()` functions and rename",
        "`odbcConnection*_()` to `odbcConnection*()`! See #699.")
    )
  }
})
