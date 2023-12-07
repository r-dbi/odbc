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
