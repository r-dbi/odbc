test_that("objectTypeIcon() gives RStudio a PNG path", {
  withr::local_envvar(POSITRON = NA)
  expect_equal(basename(objectTypeIcon("procedure")), "procedure.png")
  expect_equal(basename(objectTypeIcon("function")), "function.png")
})

test_that("objectTypeIcon() gives Positron an SVG path", {
  withr::local_envvar(POSITRON = "1")
  expect_equal(basename(objectTypeIcon("procedure")), "procedure.svg")
  expect_equal(basename(objectTypeIcon("function")), "function.svg")
})

test_that("objectTypeIcon() is NULL for types without a bundled icon", {
  expect_null(objectTypeIcon("table"))
})
