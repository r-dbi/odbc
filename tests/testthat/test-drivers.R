context("drivers")

test_that("odbcListDrivers() returns available drivers", {
  skip_on_cran()
  res <- odbcListDrivers()
  if (nrow(res) == 0) {
    skip("No drivers installed")
  }

  expect_identical(names(res), c("name", "attribute", "value"))
  expect_true(nrow(res) >= 1)
})

test_that("odbcListDrivers() keep and filter work", {
  skip_on_cran()

  current_drivers <- odbcListDrivers()[["name"]]

  if (length(current_drivers) == 0) {
    skip("No drivers installed")
  }

  res <- odbcListDrivers(filter = current_drivers)
  expect_true(nrow(res) == 0)

  res <- odbcListDrivers(keep = current_drivers[[1]])
  expect_true(nrow(res) == 1)
})

test_that("odbcListDataSources() returns available data sources", {
  skip_on_cran()

  res <- odbcListDataSources()
  if (nrow(res) == 0) {
    skip("No drivers installed")
  }

  expect_identical(names(res), c("name", "description"))
  expect_true(nrow(res) >= 1)
})

