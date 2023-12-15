test_that("odbcListDataSources() returns available data sources", {
  skip_on_cran()
  skip_if_no_drivers()

  res <- odbcListDataSources()
  if (nrow(res) == 0) {
    skip("No odbc data-sources configured")
  }
  expect_identical(names(res), c("name", "description"))
  expect_true(nrow(res) >= 1)
})
