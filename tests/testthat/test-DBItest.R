if (.Platform$OS.type == "windows") {
  quit("no")
  #DBItest::make_context(odbconnect(), list(Driver = "{SQL Server}", "Server" = "(local)\\SQL2014", "Database" = "master", "User ID" = "sa", "Password" = "Password12"), tweaks = DBItest::tweaks(), name = "odbconnect")
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
    "data_timestamp_.*",
    "data_character.*",
    "data_raw.*",
    "data_time.*", # time data not supported currently
    "data_date.*")) # date data has class in entire row rather than for each item.
DBItest::test_sql(c(
    "quote_identifier_not_vectorized",
    "append_table_error",
    "temporary_table",
    "table_visible_in_other_connection",
    "roundtrip_.*",
    NULL))
DBItest::test_meta(c("column_info", "row_count", "bind_empty"))
DBItest::test_compliance("read_only")

#DBItest::test_all(c(
  #"package_name",
  #"quote_identifier_not_vectorized",
  #"invalid_query",
  #"command_query",
  #"fetch_no_return_value", # dbClearResult not supported yet
  #"data_type_connection", # raw values not supported dbDataType not supported yet
  #"data_logical_int.*", # logicals are R logicals, not ints
  #"data_numeric.*", # Numeric types with high precision are converted to strings
  #"data_64_bit.*", # Numeric types with high precision are converted to strings
  #"data_timestamp_.*",
  #"data_time.*", # time data not supported currently
  #"data_date.*", # date data has class in entire row rather than for each item.
  #"bind_raw.*",
  #"bind.*named_colon",
  #"bind_.*named_dollar",
  #"rows_affected", # this won't work until writeTable is working
  #"fetch_premature_close", # these won't work until fetch() can handle the n argument.
  #"stale_result_warning", # Warnings for more than one result, not sure why we
  ## want this actually, there is no technical reason to have only one active result per
  ## connection.
  #"is_valid_result", # turning this off temporarily
  ##"overwrite_table", # hanging at the moment
  ##"read_table",  hanging at the moment
  ##"append_table",  hanging at the moment
  ##"append_table_error",  hanging at the moment
  ##"roundtrip_quotes",  hanging at the moment
  ##"roundtrip_keywords",  hanging at the moment
  #NULL
#))
