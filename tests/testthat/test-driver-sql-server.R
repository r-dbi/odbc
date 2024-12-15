test_that("SQLServer", {
  DBItest::make_context(
    odbc(),
    test_connection_string("SQLSERVER"),
    tweaks = DBItest::tweaks(temporary_tables = FALSE),
    name = "SQLServer"
  )

  DBItest::test_getting_started(c(
    "package_name", # Not an error
    NULL
  ))
  DBItest::test_driver(c(
    "connect_bigint_integer",
    "connect_bigint_character",
    "connect_bigint_integer64",
    NULL
  ))
  DBItest::test_connection(c(
    NULL
  ))
  DBItest::test_result(c(
    "get_query_n_zero_rows",
    "get_query_n_incomplete",
    # TODO: fails with Pro Driver due to no "good" results returned
    "fetch_n_good_after_bad",
    "fetch_no_return_value", # TODO
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
    NULL
  ))
  DBItest::test_sql(c(
    "append_roundtrip_.*", # TODO
    "quote_string_na_is_null", # Invalid syntax
    "remove_table_missing_succeed",
    "roundtrip_character", # #10
    "roundtrip_character_native", # Possible false positive
    "roundtrip_factor", # #10
    "roundtrip_time", # TODO
    "roundtrip_timestamp", # We explicitly want to set tzone to UTC regardless of input
    "write_table_error", # TODO
    "quote_string_roundtrip",
    "quote_literal_roundtrip",
    "quote_literal_na_is_null",
    "quote_literal_na_is_null",
    "create_table_error",
    "roundtrip_64_bit_roundtrip",
    "write_table_row_names_default",
    "list_fields_wrong_table",
    "list_fields_quoted",
    "list_fields_object",
    "list_objects_features",
    NULL
  ))
  DBItest::test_meta(c(
    "column_info_consistent", # TODO
    "bind_empty",
    "rows_affected_query",
    "rows_affected_statement",
    "has_completed_statement",
    "get_statement_statement",
    "row_count_statement",
    NULL
  ))
  DBItest::test_transaction(c(
    NULL
  ))
  DBItest::test_compliance(c(
    "compliance", # We are defining additional subclasses for OdbcConnections
    "reexport",
    NULL
  ))
})

test_that("works with schemas (#197)", {
  con <- test_con("SQLSERVER")
  dbExecute(con, "DROP SCHEMA IF EXISTS testSchema")
  dbExecute(con, "CREATE SCHEMA testSchema")
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

  # Test: We can enumerate schemas out of catalog ( #527 )
  # Part 1: Make sure we can see the schema we created in the
  # current catalog.
  res <- odbcConnectionSchemas(con)
  expect_true("testSchema" %in% res)
  # Part 2: Make sure we don't see that schema in the tempdb
  # listing ( out of catalog schema listing )
  res <- odbcConnectionSchemas(con, catalog_name = "tempdb")
  # Should, at least, have INFORMATION_SCHEMA and sys
  expect_true(length(res) > 1)
  expect_false("testSchema" %in% res)
})

test_that("works with dbAppendTable (#215)", {
  con <- test_con("SQLSERVER")

  ir <- iris
  ir$Species <- as.character(ir$Species)

  tbl <- local_table(con, "iris", ir)
  dbAppendTable(con, tbl, ir)

  res <- dbReadTable(con, tbl)
  expect_equal(res, rbind(ir, ir))
})

test_that("Subseconds are retained upon insertion (#208)", {
  con <- test_con("SQLSERVER")
  data <- data.frame(time = Sys.time())
  tbl <- local_table(con, "time", data)

  res <- dbReadTable(con, tbl)
  expect_equal(as.double(res$time), as.double(data$time))
})

test_that("dbWriteTable errors if field.types don't exist (#271)", {
  con <- test_con("SQLSERVER")

  expect_snapshot(
    sqlCreateTable(con, "foo", iris, field.types = list(bar = "[int]"))
  )
})

test_that("blobs can be retrieved out of order", {
  con <- test_con("SQLSERVER")
  values <- data.frame(
    c1 = 1,
    c2 = "this is varchar max",
    c3 = 11,
    c4 = "this is text",
    stringsAsFactors = FALSE
  )
  tbl <- local_table(con, "test_out_of_order_blob", values)

  received <- DBI::dbReadTable(con, tbl)
  expect_equal(received, values)

  # Also test retrival using a prepared statement
  received2 <- dbGetQuery(con,
    paste0("SELECT * FROM ", tbl, "  WHERE c1 = ?"),
    params = list(1L)
  )
  expect_equal(received2, values)
})

test_that("can bind NA values", {
  con <- test_con("SQLSERVER")
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
    stringsAsFactors = FALSE
  )
  tbl <- local_table(con, "test_na", values)

  received <- DBI::dbReadTable(con, tbl)
  expect_equal(values[-6], received[-6])
  expect_equal(as.double(values[[6]]), as.double(received[[6]]))
})

test_that("can parse SQL server identifiers", {
  con <- test_con("SQLSERVER")
  input <- DBI::SQL(c(
    "testtable",
    "[testtable]",
    "[\"testtable\"]",
    "testta[ble",
    "testta]ble",
    "[testschema].[testtable]",
    "[testschema].testtable",
    "[testdb].[testschema].[testtable]",
    "[testdb].[testschema].testtable"
  ))
  expected <- c(
    DBI::Id("testtable"),
    DBI::Id("testtable"),
    DBI::Id("testtable"),
    DBI::Id("testta[ble"),
    DBI::Id("testta]ble"),
    DBI::Id("testschema", "testtable"),
    DBI::Id("testschema", "testtable"),
    DBI::Id("testdb", "testschema", "testtable"),
    DBI::Id("testdb", "testschema", "testtable")
  )
  expect_identical(DBI::dbUnquoteIdentifier(con, input), expected)
})

test_that("odbcPreviewObject doesn't warn about pending rows", {
  con <- test_con("SQLSERVER")
  tbl <- local_table(con, "test_preview", data.frame(a = 1:10L))

  # There should be no "Pending rows" warning
  expect_no_warning({
    res <- odbcPreviewObject(con, rowLimit = 3, table = tbl)
  })
  expect_equal(nrow(res), 3)
})

test_that("dates should always be interpreted in the system time zone (#398)", {
  con <- test_con("SQLSERVER")
  # TODO: resolve the issue requiring this skip
  skip_if(grepl("RStudio", dbGetInfo(con)$drivername), "Pro Drivers fail this test.")
  res <- dbGetQuery(con, "SELECT CAST(? AS date)", params = as.Date("2019-01-01"))
  expect_equal(res[[1]], as.Date("2019-01-01"))
})

test_that("UTF in VARCHAR is not truncated", {
  con <- test_con("SQLSERVER")
  value <- "grün"
  res <- dbGetQuery(
    con,
    paste0("SELECT '", value, "' AS colone")
  )
  expect_equal(value, res[[1]])
})

test_that("Zero-row-fetch does not move cursor", {
  con <- test_con("SQLSERVER")
  tbl <- local_table(con, "test_zero_row_fetch", mtcars[1:2, ])

  rs <- dbSendStatement(con, paste0("SELECT * FROM ", tbl))
  expect_equal(nrow(dbFetch(rs, n = 0)), 0)
  expect_equal(nrow(dbFetch(rs, n = 10)), 2)
  dbClearResult(rs)
})

test_that("isTempTable handles variety of temporary specifications", {
  con <- test_con("SQLSERVER")
  expect_true(isTempTable(con, "#myTmp"))
  expect_true(isTempTable(con, "#myTmp", catalog_name = "tempdb"))
  expect_true(isTempTable(con, "#myTmp", catalog_name = "%"))
  expect_true(isTempTable(con, "#myTmp", catalog_name = NULL))
  expect_true(!isTempTable(con, "##myTmp"))
  expect_true(!isTempTable(con, "#myTmp", catalog_name = "abc"))
})

test_that("dbExistsTable accounts for local temp tables", {
  con <- test_con("SQLSERVER")
  tbl_name <- "#myTemp"
  tbl_name2 <- "##myTemp"
  tbl_name3 <- "#myTemp2"
  DBI::dbExecute(con, paste0("CREATE TABLE ", tbl_name, " (
    id int not null,
    primary key (id) )"), immediate = TRUE)
  expect_true(dbExistsTable(con, tbl_name))
  expect_true(dbExistsTable(con, tbl_name, catalog_name = "tempdb"))
  # Fail because not recognized as temp table ( catalog not tempdb )
  expect_true(!dbExistsTable(con, tbl_name, catalog_name = "abc"))
  # Fail because not recognized as temp table ( second char "#" )
  expect_true(!dbExistsTable(con, tbl_name2, catalog_name = "tempdb"))
  # Fail because table not actually present
  expect_true(!dbExistsTable(con, tbl_name3, catalog_name = "tempdb"))

  # fail because table was created in another live session
  con2 <- test_con("SQLSERVER")
  expect_true(!dbExistsTable(con2, tbl_name))
})

test_that("can create / write to temp table", {
  con <- test_con("SQLSERVER")
  locTblName <- "#myloctmp"

  df <- data.frame(name = c("one", "two"), value = c(1, 2))
  values <- sqlData(con, row.names = FALSE, df[, , drop = FALSE])

  nm <- dbQuoteIdentifier(con, locTblName)
  fields <- createFields(con, values, row.names = FALSE, field.types = NULL)
  expected <- DBI::SQL(paste0(
    "CREATE TABLE ", nm, " (\n",
    "  ", paste(fields, collapse = ",\n  "), "\n)\n"
  ))

  ret1 <- sqlCreateTable(con, locTblName, values, temporary = TRUE)
  expect_equal(ret1, expected)

  ret2 <- sqlCreateTable(con, locTblName, values, temporary = FALSE)
  expect_equal(ret2, expected)

  dbWriteTable(con, locTblName, mtcars, row.names = TRUE)
  res <- dbGetQuery(con, paste0("SELECT * FROM ", locTblName))
  expect_equal(mtcars$mpg, res$mpg)
  dbAppendTable(con, locTblName, mtcars)
  res <- dbGetQuery(con, paste0("SELECT * FROM ", locTblName))
  expect_equal(nrow(res), 2 * nrow(mtcars))

  globTblName <- "##myglobtmp"
  expect_snapshot_warning(sqlCreateTable(con, globTblName, values, temporary = TRUE))
  expect_no_warning(sqlCreateTable(con, globTblName, values, temporary = FALSE))
  # ensure we include global temp tables in dbListTables output (#509)
  local_table(con, globTblName, mtcars)
  expect_true(globTblName %in% dbListTables(con))

  notTempTblName <- "nottemp"
  expect_snapshot_warning(sqlCreateTable(con, notTempTblName, values, temporary = TRUE))
  expect_no_warning(sqlCreateTable(con, notTempTblName, values, temporary = FALSE))
})

test_that("independent encoding of column entries and names (#834)", {
  skip_on_os("windows")
  # PRO Driver does not present "AutoTranslate" option.
  # Cursory investigation seems to indicate behavior is equivalent
  # to AutoTranslate being set to "yes" ( character data is returned
  # as UTF encoded, rather than in the code page corresponding to the
  # collation ).
  skip_if(Sys.getenv("ODBC_DRIVERS_VINTAGE") != "OEM")
  rawVal1 <- as.raw(c(0x72, 0xc3, 0xa6, 0x76, 0x65, 0x6e))
  rawVal2 <- as.raw(c(0xc3, 0xa5, 0x6c, 0x65, 0x6e, 0x73))
  rawVal3 <- as.raw(c(0xc3, 0xb8, 0x72, 0x72, 0x65, 0x64))
  rawCol <-  as.raw(c(0x62, 0xc3, 0xb8, 0x76, 0x73))
  df <- data.frame(
    var_char_col = c('kanin', rawToChar(rawVal1), rawToChar(rawVal2), rawToChar(rawVal3)),
    col = 1
  )
  colnames(df)[2] <- rawToChar(rawCol)
  conn <- test_con("SQLSERVER", encoding = "latin1", AutoTranslate = "no")
  on.exit({
    dbExecute(conn, "DROP TABLE deleteme_Danish_Norwegian_CI_AS.testschema.deleteme")
    dbExecute(conn, "DROP SCHEMA IF EXISTS testschema")
    dbExecute(conn, "USE tempdb")
    dbExecute(conn, "DROP DATABASE IF EXISTS deleteme_Danish_Norwegian_CI_AS")
  })
  DBI::dbExecute(conn, "CREATE DATABASE deleteme_Danish_Norwegian_CI_AS COLLATE Danish_Norwegian_CI_AS")
  DBI::dbExecute(conn, "USE deleteme_Danish_Norwegian_CI_AS")
  DBI::dbExecute(conn, "CREATE SCHEMA testschema")
  tbl_id <- DBI::Id(catalog = "deleteme_Danish_Norwegian_CI_AS", schema = "testschema", name = "deleteme")
  DBI::dbWriteTable(conn, name = tbl_id, df, field.types = c('var_char_col' = 'varchar(5)'), overwrite = TRUE)
  res <- DBI::dbReadTable(conn, tbl_id)
  expect_identical(df, res)
})
