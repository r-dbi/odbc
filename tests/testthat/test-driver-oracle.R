test_that("can round columns", {
  con <- test_con("ORACLE")
  # - Date does not roundtrip correctly since
  #   their DATE data-type contains hour/min/seconds.
  #   To avoid loss of precision we read it in as
  #   POSIXct.
  # - There also looks like there are issues related
  #   to binary elements of size zero.
  # - Finally, no boolean in Oracle prior to 23
  test_roundtrip(con, columns = c("time", "date", "binary", "logical"))
})

test_that("can detect existence of table", {
  con <- test_con("ORACLE")

  tbl1 <- local_table(con, "mtcarstest", mtcars)
  expect_true(dbExistsTable(con, tbl1))

  tbl2 <- local_table(con, "mtcars_test", mtcars)
  expect_true(dbExistsTable(con, tbl2))
})

test_that("Writing date/datetime with batch size > 1", {
  # See #349, #350, #391
  con <- test_con("ORACLE")

  values <- data.frame(
    datetime = as.POSIXct(as.numeric(iris$Petal.Length * 10), origin = "2024-01-01", tz = "UTC"),
    date    = as.Date(as.numeric(iris$Petal.Length * 10), origin = "2024-01-01", tz = "UTC"),
    integer = as.integer(iris$Petal.Width * 100),
    double = iris$Sepal.Length,
    varchar = iris$Species)
  tbl <- local_table(con, "test_batched_write_w_dates", values)
  res <- dbReadTable(con, "test_batched_write_w_dates")
  expect_true(nrow(res) == nrow(values))
})
