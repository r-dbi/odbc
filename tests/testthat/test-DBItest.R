if (.Platform$OS.type == "windows") {
	DBItest::make_context(odbconnect(), list(Driver = "{SQL Server}", "Server" = "(local)\\SQL2014", "Database" = "master", "User ID" = "sa", "Password" = "Password12"), tweaks = DBItest::tweaks(), name = "odbconnect")
} else {
  DBItest::make_context(odbconnect(), list(dsn = "PostgreSQL"), tweaks = DBItest::tweaks(), name = "odbconnect")
}

DBItest::test_getting_started("package_name")
DBItest::test_driver()
DBItest::test_connection(c(".*stress.*", "data_type_connection"))
DBItest::test_result(
  c("stale_result_warning",
    "fetch_no_return_value",
    "data_numeric.*",
    "data_logical_int.*",
    "data_numeric.*", # Numeric types with high precision are converted to strings
    "data_64_bit.*", # Numeric types with high precision are converted to strings
    "data_character.*", # Character encodings are not preserved (on R side)
    "data_raw.*",
    "data_type_connection",
    "data_time.*", # timezones not quite working right yet
    "data_date.*",
    NULL)) # date data has class in entire row rather than for each item.
DBItest::test_sql(c(
    "quote_identifier_not_vectorized", # https://github.com/rstats-db/DBI/issues/71
    "append_table_error",
    "temporary_table",
    "roundtrip_.*",
    NULL))
#DBItest::test_meta(c("column_info", "bind_empty"))
DBItest::test_compliance("read_only")
