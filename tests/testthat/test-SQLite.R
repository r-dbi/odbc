test_that("SQLite", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(.connection_string = Sys.getenv("ODBC_CS")),
      tweaks = DBItest::tweaks(placeholder_pattern = "?", strict_identifier = TRUE), name = "SQLite")
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver(c(
      "connect_format",
      "connect_bigint_numeric",
      "connect_bigint_character",
      "connect_bigint_integer64",
      NULL))
  DBItest::test_connection(c(
      "data_type_connection",
      NULL))
  DBItest::test_result(c(
      "data_logical$", # Not an error
      "data_64_bit.*", # TODO
      "data_integer", # These tests are returned as strings by SQLite (bug?)
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # time objects not supported
      "^data_timestamp.*", # SQLite doesn't do timestamps
      "^data_date.*", # SQLite doesn't do dates
      "send_query_params", # TODO
      "fetch_n_bad", # TODO
      "fetch_n_good_after_bad", # TODO
      "fetch_no_return_value", # TODO
      "fetch_n_multi_row_inf", # TODO
      "get_query_n_bad", # TODO
      "get_query_good_after_bad_n", # TODO
      "get_query_n_multi_row_inf", # TODO
      "get_query_n_zero_rows", # TODO
      "get_query_n_incomplete", # TODO
      "get_query_params", # TODO
      "send_statement_params", # TODO
      "execute_params", # TODO
      "data_numeric", # TODO
      "clear_result_return_statement",
      "cannot_clear_result_twice_statement",
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_special", # #7
      "roundtrip_timestamp.*", # SQLite doesn't do timestamps
      "roundtrip_date.*", # SQLite doesn't do timestamps
      "roundtrip_logical", # Not an error
      "read_table", # #7

      "exists_table_temporary",
      "list_tables_temporary",
      "list_objects_temporary",
      "list_fields_temporary",

      # These work locally but fail on travis due to an old SQLite version
      "roundtrip_integer",
      "roundtrip_numeric.*",
      "roundtrip_character",
      "roundtrip_factor",
      "roundtrip_raw",
      "quote_identifier_vectorized", # TODO
      "quote_identifier_string", # TODO
      "unquote_identifier_vectorized", # TODO
      "read_table_empty", # TODO
      "read_table_row_names_na_missing", # TODO
      "create_table_overwrite", # TODO
      "create_table_error", # TODO
      "create_temporary_table", # TODO
      "create_table_visible_in_other_connection", # TODO
      "append_table_missing", # TODO
      "append_table_append_incompatible", # TODO
      "append_roundtrip_.*", # TODO
      "append_table_name", # TODO
      "append_table_row_names_false", # TODO
      "write_table_error", # TODO
      "overwrite_table", # TODO
      "overwrite_table_missing", # TODO
      "append_table", # TODO
      "append_table_new", # TODO
      "temporary_table", # TODO
      "table_visible_in_other_connection", # TODO
      "roundtrip_64_bit_roundtrip", # TODO
      "roundtrip_time", # TODO
      "roundtrip_field_types", # TODO
      "write_table_row_names_.*", # TODO
      "list_tables", # TODO
      "exists_table", # TODO
      "remove_table_temporary_arg", # TODO
      "remove_table_missing_succeed", # TODO
      "remove_table_temporary", # TODO
      "list_objects", # TODO
      "list_objects_features", # TODO
      "list_fields", # TODO
      "list_fields_wrong_table", # TODO
      "list_fields_quoted", # TODO
      "list_fields_object", # TODO
      "exists_table_name",
      "read_table_name",
      "write_table_name",
      "remove_table_name",
      "write_table_append_incompatible",
      NULL))
  DBItest::test_meta(c(
      "column_info_consistent", # TODO
      "row_count_statement", # TODO
      "rows_affected_statement", # TODO
      "rows_affected_query", # TODO
      "has_completed_statement",
      "get_statement_statement",
      "bind_.*", # TODO
      NULL))
  DBItest::test_transaction(c(
      "begin_write_disconnect",
      NULL))
  DBItest::test_compliance(c(
      "reexport", # TODO
      NULL))


  context("custom tests")
  local({
    ## Test that trying to write unsupported types (like complex numbers) throws an
    ## informative error message
    con <- DBItest:::connect(DBItest:::get_default_context())

    df <- data.frame(foo = complex(1))
    expect_error(dbWriteTable(con, "df", df), "Column 'foo' is of unsupported type: 'complex'")
  })
  test_that("odbcPreviewObject", {
    tblName <- "test_preview"
    con <- DBItest:::connect(DBItest:::get_default_context())
    dbWriteTable(con, tblName, data.frame(a = 1:10L))
    on.exit(dbRemoveTable(con, tblName))
    # There should be no "Pending rows" warning
    expect_no_warning({
      res <- odbcPreviewObject(con, rowLimit = 3, table = tblName)
    })
    expect_equal(nrow(res), 3)
  })
})
