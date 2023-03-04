test_that("MySQL", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(.connection_string = Sys.getenv("ODBC_CS")),
      tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "MySQL")
  })

  DBItest::test_getting_started(c(
      "package_name",                    # Not an error
      NULL))
  DBItest::test_driver("connect_format")
  DBItest::test_connection(c(
      NULL))
  DBItest::test_result(c(
      "fetch_n_bad",                     # TODO
      "fetch_n_good_after_bad",          # TODO
      "fetch_n_multi_row_inf",          # TODO
      "fetch_no_return_value",           # TODO
      "get_query_n_bad",                     # todo
      "get_query_good_after_bad_n",                     # todo
      "get_query_n_zero_rows",                     # todo
      "get_query_n_incomplete",                     # todo
      "get_query_n_multi_row_inf",                     # todo
      "fetch_no_return_value",           # TODO
      "data_logical($|_.+)",             # Not an error, PostgreSQL has a logical data type
      "data_raw.*",                      # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_timestamp.*",               # MySQL converts the timestamps from local times, so they roundtrip unexpectedly
      "data_character", # Strange MySQL Error only reproducible on travis
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "roundtrip_logical",               # Not an error, PostgreSQL has a logical data type
      "roundtrip_timestamp",             # We explicitly want to set tzone to UTC regardless of input
      "roundtrip_time",
      "roundtrip_raw", #TODO
      "list_tables",
      ".*_table_name",
      "write_table_error", # TODO
      "roundtrip_character", # Strange MySQL Error only reproducible on travis
      "roundtrip_character_native", # Strange MySQL Error only reproducible on travis
      "roundtrip_factor", # Strange MySQL Error only reproducible on travis
      "unquote_identifier_vectorized",
      "unquote_identifier_roundtrip",
      "unquote_identifier_special",
      "create_table_error",
      "append_roundtrip_.*",
      "roundtrip_64_bit_roundtrip",
      "write_table_row_names_default",
      "remove_table_temporary_arg",
      "remove_table_missing_succeed",
      "remove_table_temporary",
      "list_objects",
      "list_objects_features",
      "list_fields_wrong_table",
      "list_fields_quoted",
      "list_fields_object",
      "list_tables_quote",
      "list_objects_quote",
      NULL))
  DBItest::test_meta(c(
      "rows_affected_query", # The MySQL Driver returns 1 affected row
      "rows_affected_statement",
      "row_count_statement",
      "column_info_consistent",
      "bind_.*",
      "has_completed_statement",
      "get_statement_statement",
      NULL))
  DBItest::test_transaction(c(
      NULL))
  DBItest::test_compliance(c(
      "compliance",                      # We are defining additional subclasses for OdbcConnections
      "reexport",
      NULL))

  test_roundtrip(columns = "logical")
  context("custom tests")
  test_that("odbcPreviewObject", {
    tblName <- "test_preview"
    con <- DBItest:::connect(DBItest:::get_default_context())
    dbWriteTable(con, tblName, data.frame(a = 1:10L))
    on.exit(dbRemoveTable(con, tblName))
    # There should be no "Pending rows" warning
    expect_no_warning({
      res <- odbcPreviewObject(con, rowLimit = 3, table = tblName)
    })
    expect_equal(nrow(res), 3)
  })
  test_that("sproc result retrieval", {
    sprocName <- "testSproc"
    con <- DBItest:::connect(DBItest:::get_default_context())
    DBI::dbExecute(con,
      paste0("CREATE PROCEDURE ", sprocName, "(IN arg INT) BEGIN SELECT 'abc' as TestCol; END"))
    on.exit(DBI::dbExecute(con, paste0("DROP PROCEDURE ", sprocName)))
    expect_no_error({
      res <- dbGetQuery(con, paste0("CALL ", sprocName, "(1)"))
    })
    expect_identical(res,
       data.frame("TestCol" = "abc", stringsAsFactors = FALSE))
  })
})
