test_that("MySQL", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(dsn = "MySQL"), tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "MySQL")
  })

  DBItest::test_getting_started(c(
      "package_name",                    # Not an error
      NULL))
  DBItest::test_driver()
  DBItest::test_connection(c(
      "cannot_disconnect_twice", # TODO
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
      "data_date_types", # Dates should be numeric, not integers
      "data_logical($|_.+)",             # Not an error, PostgreSQL has a logical data type
      "data_raw.*",                      # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_timestamp.*",               # MySQL converts the timestamps from local times, so they roundtrip unexpectedly
      "^data_timestamp_utc.*",           # syntax not supported
      "^data_timestamp_parens.*",        # syntax not supported
      "data_character", # Strange MySQL Error only reproducible on travis
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "roundtrip_logical",               # Not an error, PostgreSQL has a logical data type
      "roundtrip_numeric_special",       # 6
      "roundtrip_timestamp",             # We explicitly want to set tzone to UTC regardless of input
      "roundtrip_raw", #TODO
      "list_tables",
      ".*_table_name",
      "write_table_error", # TODO
      "roundtrip_character", # Strange MySQL Error only reproducible on travis
      "roundtrip_character_native", # Strange MySQL Error only reproducible on travis
      "roundtrip_factor", # Strange MySQL Error only reproducible on travis
      NULL))
  DBItest::test_meta(c(
      "rows_affected_query", # The MySQL Driver returns 1 affected row
      NULL))
  #DBItest::test_transaction(c(
      #NULL))
  DBItest::test_compliance(c(
      "read_only",                       # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
      "compliance",                      # We are defining additional subclasses for OdbcConnections
      NULL))

  test_roundtrip(columns = "logical")
})
