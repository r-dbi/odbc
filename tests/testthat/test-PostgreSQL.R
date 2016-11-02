if (.Platform$OS.type != "windows") {
  ctx <- DBItest::make_context(odbconnect(), list(dsn = "PostgreSQL"), tweaks = DBItest::tweaks(), name = "PostgreSQL")

DBItest::test_getting_started(c(
    "package_name",
    NULL))
DBItest::test_driver()
DBItest::test_connection(c(
    NULL))
DBItest::test_result(
  c(
  "stale_result_warning",
    "data_logical_int.*",
    "data_64_bit.*", # Numeric types with high precision are converted to strings
    "data_raw.*",
    "data_time.*", # timezones not quite working right yet
    NULL))
DBItest::test_sql(c(
    "quote_identifier_not_vectorized", # https://github.com/rstats-db/DBI/issues/71
    "append_table_error",
    "temporary_table",
    "roundtrip_logical_int",
    "roundtrip_64_bit",
    "roundtrip_raw",
    "roundtrip_timestamp",
    "roundtrip_rownames",
    NULL))
DBItest::test_meta(c(
    "column_info",
    "bind_empty",
    NULL))
DBItest::test_compliance(c(
    "read_only",
    NULL))

  test_roundtrip()
}

