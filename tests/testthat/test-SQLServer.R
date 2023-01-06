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
    # Also test retrival using a prepared statement
    received2 <- dbGetQuery(con,
      paste0("SELECT * FROM ", tblName, "  WHERE c1 = ?"), params = list(1L))
    expect_equal(values, received)
    expect_equal(values, received2)
  })

  local({
    con <- DBItest:::connect(DBItest:::get_default_context())
    tblName <- "test_na"
    # With SELECT ing with the OEM SQL Server driver, everything
    # after the first column should be unbound. Test null detection for
    # unbound columns (NULL is registered after a call to nanodbc::result::get)
    values <- data.frame(
      c1 = c("this is varchar max", NA_character_),
      c2 = c(1L, NA_integer_),
      c3 = c(1.0, NA_real_),
      c4 = c(TRUE, NA),
      c5 = c(Sys.Date(), NA),
      c6 = c(Sys.time(), NA),
      stringsAsFactors = FALSE)
    dbWriteTable(con, tblName, values, field.types = list(c1 = "VARCHAR(MAX)", c2 = "INT", c3 = "FLOAT", c4 = "BIT", c5 = "DATE", c6 = "DATETIME"))
    on.exit(dbRemoveTable(con, tblName))
    received <- DBI::dbReadTable(con, tblName)
    expect_equal(values[-6], received[-6])
    expect_equal(as.double(values[[6]]), as.double(received[[6]]))
  })

  local({
    con <- DBItest:::connect(DBItest:::get_default_context())
    input <- DBI::SQL(c(
      "testtable",
      "[testtable]",
      "[\"testtable\"]",
      "testta[ble",
      "testta]ble",
      "[testschema].[testtable]",
      "[testschema].testtable",
      "[testdb].[testschema].[testtable]",
      "[testdb].[testschema].testtable" ))
    expected <- c(
      DBI::Id(table = "testtable"),
      DBI::Id(table = "testtable"),
      DBI::Id(table = "testtable"),
      DBI::Id(table = "testta[ble"),
      DBI::Id(table = "testta]ble"),
      DBI::Id(schema = "testschema", table = "testtable"),
      DBI::Id(schema = "testschema", table = "testtable"),
      DBI::Id(catalog = "testdb", schema = "testschema", table = "testtable"),
      DBI::Id(catalog = "testdb", schema = "testschema", table = "testtable"))
    expect_identical(DBI::dbUnquoteIdentifier(con, input), expected)
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

  test_that("dates should always be interpreted in the system time zone (#398)", {
    con <- DBItest:::connect(DBItest:::get_default_context(), timezone = "America/Chicago")
    res <- dbGetQuery(con, "SELECT CAST(? AS date)", params = as.Date("2019-01-01"))
    expect_equal(res[[1]], as.Date("2019-01-01"))
  })
})
