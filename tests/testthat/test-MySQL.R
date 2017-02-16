test_that("MySQL", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(dsn = "MySQL"), tweaks = DBItest::tweaks(), name = "MySQL")
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver()
  DBItest::test_connection(c(
      NULL))
  DBItest::test_result(c(
      "data_logical($|_.+)", # Not an error, PostgreSQL has a logical data type
      "data_64_bit.*", # TODO
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # time objects not supported
      "^data_timestamp.*", # MySQL converts the timestamps from local times, so they roundtrip unexpectedly
      "^data_timestamp_utc.*", # syntax not supported
      "^data_timestamp_parens.*", # syntax not supported
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "roundtrip_logical", # Not an error, PostgreSQL has a logical data type
      "roundtrip_64_bit", # TODO
      "roundtrip_numeric_special", # #6
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
      NULL))
  DBItest::test_meta(c(
      NULL))
  DBItest::test_transaction(c(
      NULL))
  DBItest::test_compliance(c(
      "read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
      NULL))

  test_roundtrip("Logical")
})
