test_that("can connect to snowflake", {
  pwd <- Sys.getenv("ODBC_PWD_SNOWFLAKE")
  if (nchar(pwd) == 0) {
    skip("Secret ODBC_PWD_SNOWFLAKE not available.")
  }

  con <- test_con("SNOWFLAKE")
})
