test_that("parse_size works", {
  expect_snapshot(error = TRUE, parse_size("foo"))

  expect_identical(parse_size(1L), 1)
  expect_identical(parse_size(1), 1)
  expect_identical(parse_size(.Machine$integer.max), as.numeric(.Machine$integer.max))
  expect_identical(parse_size(.Machine$integer.max + 1), .Machine$integer.max + 1)
})

test_that("id_field extracts correct elements", {
  expect_equal(id_field(DBI::Id("z"), "table"), "z")

  expect_equal(id_field(DBI::Id("y", "z"), "schema"), "y")
  expect_equal(id_field(DBI::Id("y", "z"), "table"), "z")

  expect_equal(id_field(DBI::Id("x", "y", "z"), "catalog"), "x")
  expect_equal(id_field(DBI::Id("x", "y", "z"), "schema"), "y")
  expect_equal(id_field(DBI::Id("x", "y", "z"), "table"), "z")
})

test_that("id_field checks inputs", {
  expect_snapshot(error = TRUE, {
    id_field(DBI::Id("a"), "foo")
    id_field(DBI::Id("a", "b", "c", "d"))
  })
})

test_that("getSelector", {
  # If no wild cards are detected always use exact comparison / ignore `exact` argument
  expect_equal(getSelector("mykey", "myvalue", exact = TRUE), " AND mykey = 'myvalue'")
  expect_equal(getSelector("mykey", "myvalue", exact = FALSE), " AND mykey = 'myvalue'")

  # If `value` contains wild cards, respect `exact`argument
  expect_equal(getSelector("mykey", "myvalu_", exact = TRUE), " AND mykey = 'myvalu_'")
  expect_equal(getSelector("mykey", "myvalu_", exact = FALSE), " AND mykey LIKE 'myvalu_'")

  expect_equal(getSelector("mykey", "myvalu%", exact = TRUE), " AND mykey = 'myvalu%'")
  expect_equal(getSelector("mykey", "myvalu%", exact = FALSE), " AND mykey LIKE 'myvalu%'")

  # ... unless argument is '%' - always use 'LIKE' since this is most likely the
  # desired comparison / ignore `exact` argument
  expect_equal(getSelector("mykey", "%", exact = TRUE), " AND mykey LIKE '%'")
  expect_equal(getSelector("mykey", "%", exact = FALSE), " AND mykey LIKE '%'")
})

test_that("errors are rethrown informatively (#643, #788)", {
  skip_if_not(has_unixodbc())

  expect_snapshot(error = TRUE, dbConnect(odbc(), dsn = "does_not_exist_db"))

  con <- test_con("SQLITE")
  expect_snapshot(error = TRUE, dbExecute(con, "SELECT * FROM boopbopbopbeep"))
})

test_that("rethrow_database_error() errors well when parse_database_error() fails", {
  expect_snapshot(
    error = TRUE,
    rethrow_database_error("boop", call = NULL)
  )
})

test_that("parse_database_error() works with messages from the wild", {
  msg <- "nanodbc/nanodbc.cpp:1135: 00000
          [unixODBC][Driver Manager]Data source name not found and no default driver specified"
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))

  msg <- "nanodbc/nanodbc.cpp:1594: 07002
          [Microsoft][ODBC Driver 17 for SQL Server]COUNT field incorrect or syntax error"
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))

  msg <- "nanodbc/nanodbc.cpp:1710: 07002
          [ODBC Firebird Driver]COUNT field incorrect"
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))

  msg <- "nanodbc/nanodbc.cpp:1655: HYT00
          [Microsoft][SQL Server Native Client 11.0]Query timeout expired"
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))

  msg <- "nanodbc/nanodbc.cpp:1147: 00000
          [Microsoft][ODBC Driver 18 for SQL Server]Login timeout expired
          [Microsoft][ODBC Driver 18 for SQL Server]TCP Provider: Error code 0x2726
          [Microsoft][ODBC Driver 18 for SQL Server]A network-related or instance-specific error has occurred while establishing a connection to 127.0.0.1. Server is not found or not accessible. Check if instance name is correct and if SQL Server is configured to allow remote connections. For more information see SQL Server Books Online. "
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))
})

test_that("set_odbcsysini() works (#791)", {
  skip_on_cran()
  skip_if(is_windows())

  expect_false(identical(Sys.getenv("ODBCSYSINI"), ""))
})

test_that("check_row.names()", {
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    dbWriteTable(con, "boopery", data.frame(bop = 1), row.names = c("no", "way"))
  )
})

test_that("check_field.types()", {
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    dbWriteTable(con, "boopery", data.frame(bop = 1), field.types = "numeric")
  )
})

test_that("check_attributes()", {
  expect_snapshot(
    error = TRUE,
    con <- test_con("SQLITE", attributes = list(boop = "bop"))
  )

  expect_snapshot(
    error = TRUE,
    con <- test_con("SQLITE", attributes = list(boop = "bop", beep = "boop"))
  )
})

test_that("configure_spark() returns early on windows", {
  local_mocked_bindings(is_macos = function() {FALSE})

  expect_equal(configure_spark(), NULL)
})

test_that("configure_spark() errors informatively on failure to install unixODBC", {
  local_mocked_bindings(
    is_macos = function() {TRUE},
    locate_install_unixodbc = function() {character(0)}
  )

  expect_snapshot(databricks(), error = TRUE)
})

test_that("locate_install_unixodbc() returns reasonable values", {
  skip_if(!is_macos())
  skip_if(!has_unixodbc(), "odbcinst not available.")

  res <- locate_install_unixodbc()

  expect_true(file.exists(res[1]))
  expect_true(grepl("\\.dylib", res[1]))
})

test_that("databricks() errors informatively when spark ini isn't writeable", {
  local_mocked_bindings(is_writeable = function(path) {FALSE})
  expect_snapshot(
    write_spark_lines("", ".", ".", call2("databricks")),
    error = TRUE
  )
})

test_that("locate_config_spark() returns reasonable values", {
  simba_spark_ini <- "some/folder/simba.sparkodbc.ini"
  withr::local_envvar(SIMBASPARKINI = simba_spark_ini)
  expect_equal(locate_config_spark(), simba_spark_ini)
})

test_that("configure_unixodbc_spark() writes reasonable entries", {
  unixodbc_install_path <- "libodbcinst.dylib"
  spark_config_path <- "simba.sparkodbc.ini"

  withr::local_file(spark_config_path)

  # neither of the relevant fields already there:
  writeLines(
    c("some=entries", "not=relevant"),
    con = spark_config_path
  )

  configure_unixodbc_spark(
    unixodbc_install = unixodbc_install_path,
    spark_config = spark_config_path
  )

  expect_equal(
    readLines(spark_config_path),
    c(
      "some=entries",
      "not=relevant",
      "ODBCInstLib=libodbcinst.dylib",
      "DriverManagerEncoding=UTF-16"
    )
  )

  # both of the relevant fields are already there:
  writeLines(
    c("some=entries",
      "not=relevant",
      "ODBCInstLib=somewhere.dylib",
      "DriverManagerEncoding=UTF-8"),
    con = spark_config_path
  )

  res <- configure_unixodbc_spark(
    unixodbc_install = unixodbc_install_path,
    spark_config = spark_config_path
  )

  expect_equal(res, NULL)
  expect_equal(
    readLines(spark_config_path),
    c(
      "some=entries",
      "not=relevant",
      "ODBCInstLib=libodbcinst.dylib",
      "DriverManagerEncoding=UTF-16"
    )
  )

  # an entry is there but commented out
  writeLines(
    c("some=entries",
      "not=relevant",
      ";ODBCInstLib=somewhere.dylib",
      ";DriverManagerEncoding=UTF-8"),
    con = spark_config_path
  )

  configure_unixodbc_spark(
    unixodbc_install = unixodbc_install_path,
    spark_config = spark_config_path
  )

  expect_equal(
    readLines(spark_config_path),
    c(
      "some=entries",
      "not=relevant",
      ";ODBCInstLib=somewhere.dylib",
      ";DriverManagerEncoding=UTF-8",
      "ODBCInstLib=libodbcinst.dylib",
      "DriverManagerEncoding=UTF-16"
    )
  )
})
