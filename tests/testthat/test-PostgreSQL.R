if (.Platform$OS.type != "windows") {
  ctx <- DBItest::make_context(odbconnect(), list(dsn = "PostgreSQL"), tweaks = DBItest::tweaks(), name = "PostgreSQL")

DBItest::test_getting_started(c(
    "package_name", # Not an error
    NULL))
DBItest::test_driver()
DBItest::test_connection(c(
    NULL))
DBItest::test_result(
  c(
    "data_logical_int.*", # Not an error, PostgreSQL has a logical data type
    "data_64_bit.*", # Numeric types with high precision are converted to strings
    "data_raw.*",
    "^data_time$", "^data_time_.*", # time objects not supported
    "^data_timestamp_utc.*", # syntax not supported
    "^data_timestamp_parens.*", # syntax not supported
    NULL))
DBItest::test_sql(c(
    "quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
    "roundtrip_logical_int", # Not an error, PostgreSQL has a logical data type
    "roundtrip_64_bit",
    NULL))
DBItest::test_meta(c(
    NULL))
DBItest::test_compliance(c(
    "read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
    NULL))

  test_roundtrip()
}
