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
  expect_equal(build_connection_string(), "")
  expect_equal(build_connection_string(foo = "1"), "foo=1")
  expect_equal(build_connection_string(foo = "1", bar = "2"), "foo=1;bar=2")
})

test_that("build_connection_string automatically escapes if needed", {
  expect_equal(build_connection_string(foo = "*"), "foo={*}")
  # Already wrapped
  expect_equal(build_connection_string(foo = "{*}"), "foo={*}")
  # Respects AsIs
  expect_equal(build_connection_string(foo = I("*")), "foo=*")
})

test_that("build_connection_string combines with existing .connection string", {
  expect_equal(build_connection_string("x=1"), "x=1")
  expect_equal(build_connection_string("x=1", foo = "1"), "x=1;foo=1")
  expect_equal(build_connection_string("x=1;", foo = "1"), "x=1;foo=1")
})
