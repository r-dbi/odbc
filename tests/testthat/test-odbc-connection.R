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

# odbcConnectionColumns S4 dispatch ---------------------------------------

test_that("odbcConnectionColumns has no ambiguous (Driver, SQL) dispatch", {
  # `SQL` extends `character`, so a driver that defines only a
  # `c(Driver, "character")` method leaves `(Driver, SQL)` ambiguous against the
  # base `c("OdbcConnection", "SQL")` method, producing an S4 NOTE. Drivers that
  # override the character method must also define the SQL method.
  for (driver in c("Oracle", "Snowflake", "Microsoft SQL Server")) {
    expect_true(
      existsMethod("odbcConnectionColumns", c(driver, "SQL")),
      info = driver
    )
    # The exact method must win, with no ambiguity message emitted.
    msgs <- character()
    m <- withCallingHandlers(
      selectMethod("odbcConnectionColumns", signature(driver, "SQL")),
      message = function(c) {
        msgs <<- c(msgs, conditionMessage(c))
        invokeRestart("muffleMessage")
      }
    )
    expect_identical(as.character(m@target), c(driver, "SQL"), info = driver)
    expect_false(any(grepl("would also be valid", msgs)), info = driver)
  }
})
