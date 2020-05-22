test_that("SQLServer", {
  skip_unless_has_test_db({
      DBItest::make_context(odbc(), list(dsn = "MicrosoftSQLServer", UID="SA", PWD="Password12"), tweaks = DBItest::tweaks(temporary_tables = FALSE), name = "SQLServer")
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver(c(
    "connect_format",
    "connect_bigint_integer",
    "connect_bigint_character",
    "connect_bigint_integer64",
      NULL))
  DBItest::test_connection(c(
      NULL))
  DBItest::test_result(c(
      "fetch_n_bad",                     # TODO
      "fetch_n_good_after_bad",          # TODO
      "fetch_no_return_value",           # TODO
      "get_query_n_bad",                     # todo
      "get_query_good_after_bad_n",                     # todo
      "get_query_n_zero_rows",                     # todo
      "get_query_n_multi_row_inf",
      "get_query_n_incomplete",
      "get_query_params",
      "fetch_no_return_value",           # TODO
      "fetch_n_multi_row_inf",
      ".*clear_result_.*_statement", # TODO
      "send_statement.*", # Invalid CTAS syntax
      "execute_atomic", # Invalid CTAS syntax
      "execute_immediate", # Invalid CTAS syntax
      "data_character", # I think the test is bad
      "data_logical$", # Not an error
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
      "quote_identifier_vectorized", # TODO
      "quote_identifier", # Invalid Syntax
      "quote_identifier_special", # TODO
      "remove_table_temporary_arg",
      "remove_table_missing_succeed",
      "remove_table_missing_succeed",
      "temporary_table", # Unsupported
      "roundtrip_character", # #10
      "roundtrip_character_native", # Possible false positive
      "roundtrip_factor", # #10
      "roundtrip_time", #TODO
      "roundtrip_date", # unsupported
      "roundtrip_quotes", # TODO, not sure why this is failing
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
      "write_table_error", # TODO
      "list_tables", # TODO
      ".*_table_name", # TODO
      "append_table_error", # TODO
      "quote_string_roundtrip",
      "quote_literal_roundtrip",
      "quote_literal_na_is_null",
      "quote_literal_na_is_null",
      "unquote_identifier_vectorized",
      "read_table_empty",
      "create_table_error",
      "create_temporary_table",
      "write_table_append_incompatible",
      "roundtrip_64_bit_roundtrip",
      "roundtrip_field_types",
      "write_table_row_names_default",
      "remove_table_temporary",
      "list_objects_features",
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

    expect_error(
      dbWriteTable(con, "foo", iris, field.types = list(foo = "VARCHAR(10)", bar = "double")),
      "Columns in `field.types` must be in the input"
    )
  })
})
