test_that("PostgreSQL", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(dsn = "PostgreSQL"), tweaks = DBItest::tweaks(temporary_tables = FALSE, placeholder_pattern = "?"), name = "PostgreSQL")
  })

  context("custom tests")
  test_that("show method works as expected with real connection", {
    skip_on_os("windows")
    con <- dbConnect(odbc(), "PostgreSQL")

    expect_output(show(con), "postgres@localhost")
    expect_output(show(con), "Database: test_db")
    expect_output(show(con), "PostgreSQL Version: ")
  })

  test_that("64 bit integers work with alternate mappings", {
    con_default <- dbConnect(odbc(), "PostgreSQL")
    con_integer64 <- dbConnect(odbc(), "PostgreSQL", bigint = "integer64")
    con_integer <- dbConnect(odbc(), "PostgreSQL", bigint = "integer")
    con_numeric <- dbConnect(odbc(), "PostgreSQL", bigint = "numeric")
    con_character <- dbConnect(odbc(), "PostgreSQL", bigint = "character")

    dbWriteTable(con_default, "test", data.frame(a = 1:10L), field.types = c(a = "BIGINT"))
    on.exit(dbRemoveTable(con_default, "test"))

    expect_is(dbReadTable(con_default, "test")$a, "integer64")
    expect_is(dbReadTable(con_integer64, "test")$a, "integer64")

    expect_is(dbReadTable(con_integer, "test")$a, "integer")

    expect_is(dbReadTable(con_numeric, "test")$a, "numeric")

    expect_is(dbReadTable(con_character, "test")$a, "character")
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
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
      "data_logical_int.*", # Not an error, PostgreSQL has a logical data type
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # `time()` function is not valid syntax
      "^data_timestamp.*", # We explicitly want to set tzone to UTC
      "^data_timestamp_utc.*", # syntax not supported
      "^data_timestamp_parens.*", # syntax not supported
      "data_64_bit_numeric_warning", # TODO
      "data_64_bit_lossless", # TODO
      "send_query_syntax_error", # TODO
      "get_query_syntax_error", # TODO
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "quote_identifier_special", # TODO
      "roundtrip_logical_int", # Not an error, PostgreSQL has a logical data type
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC
      "roundtrip_numeric_special",       # 6
      "roundtrip_raw", #TODO
      "list_tables",
      ".*_table_name",
      "write_table_error", # TODO
      NULL))
  DBItest::test_meta(c(
      "bind_logical", # DBItest coerces this to character
      "bind_multi_row.*", # We do not current support multi row binding
      "bind_timestamp_lt", # We do not support POSIXlt objects
      "bind_raw", # This test seems to be not quite working as expected
      "bind_.*",
      NULL))
  #DBItest::test_transaction(c(
      #NULL))
  DBItest::test_compliance(c(
      "read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
      "compliance", # We are defining additional subclasses for OdbcConnections
      NULL))

  test_roundtrip()
})
