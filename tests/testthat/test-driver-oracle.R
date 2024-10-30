test_that("Oracle", {
  DBItest::make_context(
    odbc(),
    test_connection_string("ORACLE"),
    tweaks = DBItest::tweaks(),
    name = "Oracle"
  )

  DBItest::test_getting_started(c(
    "package_name", # Not an error
    NULL
  ))
  DBItest::test_driver(c(
    "connect_bigint_integer",
    "connect_bigint_numeric",
    "connect_bigint_character",
    "connect_bigint_integer64"
  ))
  DBItest::test_connection()
  DBItest::test_result(c(
    "send_query.*",
    "fetch.*",
    "clear_result_return_query",
    "clear_result_return_statement",
    "clear_result_return_query_arrow",
    "cannot_clear_result_twice_query",
    "cannot_clear_result_twice_statement",
    "get_query_atomic",
    "cannot_clear_result_twice_query_arrow",
    "get_query.*",
    "send_statement.*",
    "execute_atomic",
    "execute_params",
    "execute_immediate",
    "data.*"
  ))
  DBItest::test_sql(c(
    "quote_string.*",
    "quote_literal.*",
    "quote_identifier.*",
    "read_table.*",
    "create_table.*",
    "create_table_visible.*",
    "create_roundtrip_quotes",
    "append_roundtrip_quotes_column_names",
    "append_roundtrip.*",
    "write_table.*",
    "overwrite_table.*",
    "append_table.*",
    "temporary_table.*",
    "table_visible.*",
    "roundtrip.*",
    "remove_table.*",
    "list_objects_features",
    "list_fields_wrong_table"
  ))
  DBItest::test_meta(c(
    "bind.*",
    "is_valid_result_query",
    "has_completed.*",
    "get_statement.*",
    "column_info.*",
    "row_count.*",
    "get_row_count_error",
    "rows_affected.*",
    "get_info_result"
  ))
  DBItest::test_transaction("begin_write_commit.*")
  DBItest::test_compliance("reexport")
})

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
