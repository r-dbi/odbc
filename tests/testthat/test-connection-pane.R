test_that("objectTypeIcon() gives RStudio a PNG path", {
  withr::local_envvar(POSITRON = NA)
  expect_equal(basename(objectTypeIcon("procedure")), "procedure.png")
  expect_equal(basename(objectTypeIcon("function")), "function.png")
})

test_that("objectTypeIcon() gives Positron an SVG data URI", {
  withr::local_envvar(POSITRON = "1")
  expect_match(objectTypeIcon("procedure"), "^data:image/svg\\+xml;base64,")
  expect_match(objectTypeIcon("function"), "^data:image/svg\\+xml;base64,")
})

test_that("objectTypeIcon() is NULL for types without a bundled icon", {
  expect_null(objectTypeIcon("table"))
})
