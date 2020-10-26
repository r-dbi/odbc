test_that("SQLServer", {
  skip_unless_has_test_db({
      DBItest::make_context(odbc(), list(dsn = "MicrosoftSQLServer", UID="SA", PWD="Password12"), tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "SQLServer")
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver(c(
    "connect_bigint_integer",
    "connect_bigint_character",
    "connect_bigint_integer64",
      NULL))
  DBItest::test_connection(c(
      NULL))
  DBItest::test_result(c(
      "get_query_n_zero_rows",
      "get_query_n_incomplete",
      "fetch_no_return_value",           # TODO
      "clear_result_return_statement",
      "cannot_clear_result_twice_statement",
      "send_statement.*", # Invalid CTAS syntax
      "execute_atomic", # Invalid CTAS syntax
      "execute_immediate", # Invalid CTAS syntax
      "data_character", # I think the test is bad
      "data_64_bit_numeric_warning", # Test does not explicitly set 64 bit columns
      "data_64_bit_lossless", # Test does not explicitly set 64 bit columns
      "data_date.*", # Date not a builtin function name
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # time objects not supported
      "^data_timestamp.*", # syntax not supported
      NULL))
  DBItest::test_sql(c(
      "append_roundtrip_.*", # TODO
      "quote_string_na_is_null", # Invalid syntax
      "remove_table_missing_succeed",
      "roundtrip_character", # #10
      "roundtrip_character_native", # Possible false positive
      "roundtrip_factor", # #10
      "roundtrip_time", #TODO
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
      "write_table_error", # TODO
      "quote_string_roundtrip",
      "quote_literal_roundtrip",
      "quote_literal_na_is_null",
      "quote_literal_na_is_null",
      "create_table_error",
      "create_temporary_table",
      "roundtrip_64_bit_roundtrip",
      "write_table_row_names_default",
      "list_fields_wrong_table",
      "list_fields_quoted",
      "list_fields_object",
      NULL))
  DBItest::test_meta(c(
      "column_info_consistent", # TODO
      "bind_empty",
      "rows_affected_query",
      "rows_affected_statement",
      "has_completed_statement",
      "get_statement_statement",
      "row_count_statement",
      NULL))
   DBItest::test_transaction(c(
       NULL))
  DBItest::test_compliance(c(
      "compliance", # We are defining additional subclasses for OdbcConnections
      "reexport",
      NULL))

  local({
    # SQLServer works with schemas (#197)
    con <- DBItest:::connect(DBItest:::get_default_context())
    dbExecute(con, "DROP SCHEMA IF EXISTS testSchema")
    dbExecute(con, 'CREATE SCHEMA testSchema')
    on.exit({
      dbExecute(con, "DROP TABLE testSchema.iris")
      dbExecute(con, "DROP SCHEMA testSchema")
    })

    ir <- iris
    ir$Species <- as.character(ir$Species)

    table_id <- Id(schema = "testSchema", table = "iris")
    dbWriteTable(conn = con, name = table_id, value = ir)
    dbWriteTable(conn = con, name = table_id, value = ir, append = TRUE)

    res <- dbReadTable(con, table_id)
    expect_equal(res, rbind(ir, ir))

    dbWriteTable(conn = con, name = table_id, value = ir, overwrite = TRUE)
    res <- dbReadTable(con, table_id)
    expect_equal(res, ir)
  })

  local({
    # SQLServer works with dbAppendTable (#215)
    con <- DBItest:::connect(DBItest:::get_default_context())

    ir <- iris
    ir$Species <- as.character(ir$Species)

    dbWriteTable(con, "iris", ir)
    on.exit(dbRemoveTable(con, "iris"))

    dbAppendTable(conn = con, name = "iris", value = ir)

    res <- dbReadTable(con, "iris")
    expect_equal(res, rbind(ir, ir))
  })

  local({
    # Subseconds are retained upon insertion (#208)
    con <- DBItest:::connect(DBItest:::get_default_context())

    data <- data.frame(time = Sys.time())
    dbWriteTable(con, "time", data, field.types = list(time = "DATETIME"), overwrite = TRUE)
    on.exit(dbRemoveTable(con, "time"))
    res <- dbReadTable(con, "time")

    expect_equal(as.double(res$time), as.double(data$time))
  })

  local({
    # dbWriteTable errors if field.types don't exist (#271)
    con <- DBItest:::connect(DBItest:::get_default_context())

    on.exit(dbRemoveTable(con, "foo"), add = TRUE)
    expect_warning(
      dbWriteTable(con, "foo", iris, field.types = list(bar = "[int]")),
      "Some columns in `field.types` not in the input, missing columns:"
    )
  })

  local({
    con <- DBItest:::connect(DBItest:::get_default_context())
    tblName <- "test_out_of_order_blob"

    values <- data.frame(
      c1 = 1,
      c2 = "this is varchar max",
      c3 = 11,
      c4 = "this is text",
      stringsAsFactors = FALSE)
    dbWriteTable(con, tblName, values, field.types = list(c1 = "INT", c2 = "VARCHAR(MAX)", c3 = "INT", c4 = "TEXT"))
    on.exit(dbRemoveTable(con, tblName))
    received <- DBI::dbReadTable(con, tblName)
    expect_equal(values, received)
  })

  test_that("dates should always be interpreted in the system time zone (#398)", {
    con <- DBItest:::connect(DBItest:::get_default_context(), timezone = "America/Chicago")
    res <- dbGetQuery(con, "SELECT ?", params = as.Date("2019-01-01"))
    expect_equal(res[[1]], "2019-01-01")
  })
})
