test_that("Oracle", {

  con <- dbConnect(odbc::odbc(), .connection_string = test_connection_string("ORACLE"))
  # - Long/outstanding issue with batch inserting
  # date/datetime for Oracle.  See for example
  # #349, #350, #391
  # - There also looks like there are issues related
  # to binary elements of size zero.
  # - Finally, no boolean in Oracle prior to 23
  test_roundtrip(con, columns = c("time", "date", "datetime", "binary", "logical"))

  local({
    # Test custom dbExistsTable implementation for
    # Oracle
    dbWriteTable(con, "mtcarstest", mtcars)
    expect_true(dbExistsTable(con, "mtcarstest"))
    dbWriteTable(con, "mtcars_test", mtcars)
    expect_true(dbExistsTable(con, "mtcars_test"))
    on.exit({
      dbExecute(con, "DROP TABLE mtcarstest")
      dbExecute(con, "DROP TABLE mtcars_test")
    })
  })
})
