DBItest::make_context(odbconnect(), list("DSN=database1"), tweaks = DBItest::tweaks(), name = "odbconnect")
DBItest::test_all(c(
  "package_name",
  ".*stress.*", # TODO: Enable
  "quote_identifier_not_vectorized",
  "invalid_query",
  "command_query",
  "fetch_no_return_value", # dbClearResult not supported yet
  #"data_type_connection", # dbDataType not supported yet
  "data_timestamp_.*",
  "data_time.*", # time data not supported currently
  "bind_raw.*",
  "bind.*named_colon",
  "bind_.*named_dollar",
  "rows_affected", # this won't work until writeTable is working
  NULL
))
