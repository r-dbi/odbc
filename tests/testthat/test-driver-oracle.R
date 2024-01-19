test_that("can round columns", {
  con <- test_con("ORACLE")
  # - Long/outstanding issue with batch inserting
  # date/datetime for Oracle.  See for example
  # #349, #350, #391
  # - There also looks like there are issues related
  # to binary elements of size zero.
  # - Finally, no boolean in Oracle prior to 23
  test_roundtrip(con, columns = c("time", "date", "datetime", "binary", "logical"))
})

test_that("can detect existence of table", {
  con <- test_con("ORACLE")

  tbl1 <- local_table(con, "mtcarstest", mtcars)
  expect_true(dbExistsTable(con, tbl1))

  tbl2 <- local_table(con, "mtcars_test", mtcars)
  expect_true(dbExistsTable(con, tbl2))
})
