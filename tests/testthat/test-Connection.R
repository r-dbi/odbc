
test_that("handles NULL, pattern matching characters, and escaped text", {
  expect_equal(escapePattern(NULL), NULL)
  expect_equal(escapePattern("a%b_c"), I("a\\%b\\_c"))
  expect_equal(escapePattern(I("%%")), I("%%"))
})
