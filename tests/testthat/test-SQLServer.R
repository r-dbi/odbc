test_that("SQLServer", {
  skip_unless_has_test_db({
    if (identical(Sys.getenv("APPVEYOR"), "True")) {
      DBItest::make_context(odbc(), list(Driver ="{SQL Server}", "Server" = "(local)\\SQL2014", "Database" = "master", "User ID" = "sa", "Password" = "Password12"), tweaks = DBItest::tweaks(), name = "SQLServer")
    } else {
      DBItest::make_context(odbc(), list(dsn = "test"), tweaks = DBItest::tweaks(), name = "SQLServer")
    }
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver()
  DBItest::test_connection(c(
      NULL))
  DBItest::test_result(c(
      "data_logical$", # Not an error
      "data_logical_.*", # Not an error

      "data_date.*", # Date not a builtin function name
      "data_64_bit.*", # TODO
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # time objects not supported
      "^data_timestamp.*", # syntax not supported
      "^data_timestamp_parens.*", # syntax not supported
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "roundtrip_logical_int", # Not an error, PostgreSQL has a logical data type
      "roundtrip_64_bit", # TODO
      "temporary_table", # Unsupported
      "roundtrip_numeric_special", # Unsupported
      "roundtrip_character", # #10
      "roundtrip_factor", # #10
      "roundtrip_raw", # #10
      "roundtrip_date", # unsupported
      "roundtrip_quotes", # TODO, not sure why this is failing
      "roundtrip_rownames", # #10
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
      NULL))
  DBItest::test_meta(c(
      "bind_empty",
      NULL))
  DBItest::test_transaction(c(
      NULL))
  DBItest::test_compliance(c(
      "read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
      "compliance", # We are defining additional subclasses for OdbcConnections
      NULL))
})
