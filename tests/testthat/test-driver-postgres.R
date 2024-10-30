test_that("PostgreSQL", {
  DBItest::make_context(
    odbc(),
    test_connection_string("POSTGRES"),
    tweaks = DBItest::tweaks(temporary_tables = FALSE, placeholder_pattern = "?"),
    name = "PostgreSQL"
  )

  DBItest::test_getting_started(c(
    "package_name", # Not an error
    NULL
  ))
  DBItest::test_driver("connect_format")
  DBItest::test_connection(c(
    "clear_result_return_statement",
    "cannot_clear_result_twice_statement",
    NULL
  ))
  DBItest::test_result(c(
    "fetch_n_bad", # TODO
    "fetch_n_good_after_bad", # TODO
    "fetch_no_return_value", # TODO
    "get_query_n_bad", # todo
    "get_query_good_after_bad_n", # todo
    "get_query_n_zero_rows", # todo
    "fetch_no_return_value", # TODO
    "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
    "^data_time$", "^data_time_.*", # `time()` function is not valid syntax
    "^data_timestamp.*", # We explicitly want to set tzone to UTC
    "data_64_bit_numeric_warning", # TODO
    "data_64_bit_lossless", # TODO
    "data_integer", # Fails, unreliably on Windows
    # TODO: fails with Pro Driver with "a statement is already in progress"
    "send_query_immediate",
    # TODO: fails with Pro Driver with "a statement is already in progress"
    "send_query_only_one_result_set",
    "send_query_syntax_error", # TODO
    "get_query_syntax_error", # TODO
    "send_query_params", # TODO
    "fetch_n_multi_row_inf", # TODO
    "get_query_n_multi_row_inf", # TODO
    "get_query_n_incomplete", # TODO
    "get_query_params", # TODO
    "send_statement_params", # TODO
    "execute_params", # TODO
    NULL
  ))
  DBItest::test_sql(c(
    "quote_identifier_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
    "quote_identifier_special", # TODO
    "roundtrip_timestamp", # We explicitly want to set tzone to UTC
    "roundtrip_time",
    "roundtrip_raw", # TODO
    "list_tables",
    ".*_table_name",
    "write_table_error", # TODO
    "unquote_identifier_vectorized", # TODO
    "create_table_overwrite", # TODO
    "create_table_error", # TODO
    "append_table_.*", # TODO
    "append_roundtrip_.*", # TODO
    "append_table_.*", # TODO
    "roundtrip_64_bit_roundtrip", # TODO
    "roundtrip_character", # TODO
    "roundtrip_field_types", # TODO
    "write_table_append_incompatible",
    "write_table_row_names_default", # TODO
    "remove_table_temporary_arg", # TODO
    "remove_table_missing_succeed", # TODO
    "remove_table_temporary", # TODO
    "list_objects_features", # TODO
    "list_fields_wrong_table", # TODO
    "list_fields_quoted", # TODO
    "list_fields_object", # TODO
    NULL
  ))
  DBItest::test_meta(c(
    "arrow_.*",
    "stream_bind.*",
    "bind_.*", # TODO
    "has_completed_statement",
    "get_statement_statement",
    "column_info_consistent", # TODO
    "row_count_statement", # TODO
    "rows_affected_statement", # TODO
    "rows_affected_query", # TODO
    "get_info_result", # TODO
    NULL
  ))
  DBItest::test_transaction(c(
    NULL
  ))
  DBItest::test_compliance(c(
    "compliance", # We are defining additional subclasses for OdbcConnections
    "reexport", # TODO
    NULL
  ))
})

test_that("can roundtrip columns", {
  con <- test_con("POSTGRES")
  test_roundtrip(con)
})

test_that("show method works as expected with real connection", {
  skip_on_os("windows")
  con <- test_con("POSTGRES")

  expect_output(show(con), "@localhost")
  expect_output(show(con), "Database: [a-z]+")
  expect_output(show(con), "PostgreSQL Version: ")
})

test_that("64 bit integers work with alternate mappings", {
  con_integer64 <- test_con("POSTGRES", bigint = "integer64")
  con_integer <- test_con("POSTGRES", bigint = "integer")
  con_numeric <- test_con("POSTGRES", bigint = "numeric")
  con_character <- test_con("POSTGRES", bigint = "character")

  tbl <- local_table(
    con_integer64,
    "test",
    data.frame(a = 1:10L),
    field.types = c(a = "BIGINT")
  )

  expect_s3_class(dbReadTable(con_integer64, tbl)$a, "integer64")
  expect_type(dbReadTable(con_integer, tbl)$a, "integer")
  expect_type(dbReadTable(con_numeric, tbl)$a, "double")
  expect_type(dbReadTable(con_character, tbl)$a, "character")
})

# This test checks whether when writing to a table and using
# result_describe_parameters to offer descriptions of the data
# we are attempting to write, our logic remains robust to the
# case when the data being written has columns ordered
# differently than the table we are targetting.
test_that("Writing data.frame with column ordering different than target table", {
  con <- test_con("POSTGRES")
  values <- data.frame(
    datetime = as.POSIXct(c(14, 15), origin = "2016-01-01", tz = "UTC"),
    name = c("one", "two"),
    num = 1:2,
    stringsAsFactors = FALSE
  )
  tbl <- "test_order_write"
  dbCreateTable(con, tbl, values)
  dbAppendTable(con, tbl, values[c(2, 3, 1)])
  on.exit(dbRemoveTable(con, tbl))

  received <- dbReadTable(con, tbl)
  received <- received[order(received$num), ]
  row.names(received) <- NULL
  expect_equal(values, received)
})

test_that("odbcPreviewObject", {
  con <- test_con("POSTGRES")
  tbl <- local_table(con, "test_preview", data.frame(a = 1:10L))

  # There should be no "Pending rows" warning
  expect_no_warning({
    res <- odbcPreviewObject(con, rowLimit = 3, table = tbl)
  })
  expect_equal(nrow(res), 3)
})

