context("drivers")

test_that("odbcListDrivers() returns available drivers", {
  skip_on_cran()
  res <- odbcListDrivers()
  expect_identical(names(res), c("name", "attribute", "value"))
  expect_true(nrow(res) >= 1)
})

test_that("odbcListDrivers() honors odbc.drivers.filter option", {
  skip_on_cran()
  existing_filter <- options("odbc.drivers.filter")
  options(odbc.drivers.filter = odbcListDrivers()[["name"]])
  res <- odbcListDrivers()
  options(odbc.drivers.filter = existing_filter)
  expect_true(nrow(res) == 0)

})

test_that("odbcListDataSources() returns available data sources", {
  skip_on_cran()
  res <- odbcListDataSources()
  expect_identical(names(res), c("name", "description"))
  expect_true(nrow(res) >= 1)
})

