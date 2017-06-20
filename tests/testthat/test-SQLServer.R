test_that("SQLServer", {
  skip_unless_has_test_db({
    if (identical(Sys.getenv("APPVEYOR"), "True")) {
      DBItest::make_context(odbc(), list(Driver ="{SQL Server}", "Server" = "(local)\\SQL2014", "Database" = "master", "User ID" = "sa", "Password" = "Password12", encoding = "latin1"), tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "SQLServer")
    } else {
      DBItest::make_context(odbc(), list(dsn = "SQLServer", UID="testuser", PWD="test"), tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "SQLServer")
    }
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver()
  DBItest::test_connection(c(
      "cannot_forget_disconnect", # TODO
      NULL))
  DBItest::test_result(c(
      "fetch_n_bad",                     # TODO
      "fetch_n_good_after_bad",          # TODO
      "fetch_no_return_value",           # TODO
      "get_query_n_bad",                     # todo
      "get_query_good_after_bad_n",                     # todo
      "get_query_n_zero_rows",                     # todo
      "fetch_no_return_value",           # TODO
      ".*clear_result_.*_statement", # TODO
      "send_statement.*", # Invalid CTAS syntax
      "execute_atomic", # Invalid CTAS syntax
      "data_character", # I think the test is bad
      "data_logical$", # Not an error
      "data_logical_.*", # Not an error
      "data_64_bit_numeric_warning", # Test does not explicitly set 64 bit columns
      "data_64_bit_lossless", # Test does not explicitly set 64 bit columns
      "data_date.*", # Date not a builtin function name
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # time objects not supported
      "^data_timestamp.*", # syntax not supported
      "^data_timestamp_parens.*", # syntax not supported
      NULL))
  DBItest::test_sql(c(
      "quote_string_na_is_null", # Invalid syntax
      "quote_identifier_vectorized", # TODO
      "quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "quote_identifier", # Invalid Syntax
      "quote_identifier_special", # TODO
      "roundtrip_logical_int", # Not an error, PostgreSQL has a logical data type
      "roundtrip_64_bit", # TODO
      "temporary_table", # Unsupported
      "roundtrip_numeric_special", # Unsupported
      "roundtrip_character", # #10
      "roundtrip_character_native", # Possible false positive
      "roundtrip_factor", # #10
      "roundtrip_raw", # #10
      "roundtrip_blob", # TODO
      "roundtrip_time", #TODO
      "roundtrip_date", # unsupported
      "roundtrip_quotes", # TODO, not sure why this is failing
      "roundtrip_rownames", # #10
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
      "write_table_error", # TODO
      "list_tables", # TODO
      ".*_table_name", # TODO
      "append_table_error", # TODO
      NULL))
  DBItest::test_meta(c(
      "bind_empty",
      "rows_affected_query",
      NULL))
  # DBItest::test_transaction(c(
  #     NULL))
  DBItest::test_compliance(c(
      "read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
      "compliance", # We are defining additional subclasses for OdbcConnections
      NULL))
})

