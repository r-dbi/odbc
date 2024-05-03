test_that("can connect to snowflake", {
  odbc_pwd_snowflake <- Sys.getenv("ODBC_PWD_SNOWFLAKE")
  if (identical(odbc_pwd_snowflake, "")) {
    skip("Secret ODBC_PWD_SNOWFLAKE not available.")
  }

  con <- test_con("SNOWFLAKE")
})
