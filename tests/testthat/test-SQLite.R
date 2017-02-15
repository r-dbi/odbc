if (.Platform$OS.type != "windows") {
  #ctx <- DBItest::make_context(odbc(), list(dsn = "SQLite"), tweaks = DBItest::tweaks(), name = "SQLite")

#DBItest::test_getting_started(c(
    #"package_name", # Not an error
    #NULL))
#DBItest::test_driver()
#DBItest::test_connection(c(
    #NULL))
#DBItest::test_result(c(
    #"data_logical$", # Not an error
    #"data_logical_.*", # Not an error
    #"data_64_bit.*", # TODO
    #"data_integer_null.*", # These tests are returned as strings by SQLite (bug?)
    #"data_numeric_null.*", # These tests are returned as strings by SQLite (bug?)
    #"data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
    #"^data_time$", "^data_time_.*", # time objects not supported
    #"^data_timestamp.*", # SQLite doesn't do timestamps
    #"^data_date.*", # SQLite doesn't do dates
    #NULL))
#DBItest::test_sql(c(
    #"quote_identifier_not_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
    #"quote_identifier_special", # #7
    #"roundtrip_timestamp.*", # SQLite doesn't do timestamps
    #"roundtrip_date.*", # SQLite doesn't do timestamps
    #"roundtrip_logical", # Not an error
    #"roundtrip_logical_int", # #7
    #"roundtrip_64_bit", # TODO
    #"read_table", # #7

    ## These work locally but fail on travis due to an old SQLite version
    #"roundtrip_integer",
    #"roundtrip_numeric.*",
    #"roundtrip_character",
    #"roundtrip_factor",
    #"roundtrip_raw",
    #"roundtrip_rownames",
    #NULL))
#DBItest::test_meta(c(
    #NULL))
#DBItest::test_transaction(c(
    #NULL))
#DBItest::test_compliance(c(
    #"read_only", # Setting SQL_MODE_READ_ONLY is not supported in most DBs, so ignoring.
    #NULL))
}
