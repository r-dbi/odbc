test_that("databricks host validates inputs", {
  expect_equal(databricks_host("https://my-host.com"), "my-host.com")
  expect_snapshot(databricks_host(""), error = TRUE)
})

test_that("user agent respects envvar", {
  local_mocked_bindings(packageVersion = function(...) "1.0.0")
  expect_equal(databricks_user_agent(), "r-odbc/1.0.0")

  withr::local_envvar(SPARK_CONNECT_USER_AGENT = "my-odbc/1.0.0")
  expect_equal(databricks_user_agent(), "my-odbc/1.0.0")
})
