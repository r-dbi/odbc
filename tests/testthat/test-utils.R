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

  # message contains brackets that may be interpreted as inline markup (#859)
  msg <- "nanodbc/nanodbc.cpp:1722: S1000
          [SAP AG][LIBODBCHDB DLL][HDBODBC] General error;403 internal error: Error opening the cursor for the remote database <***.***> [SAP AG][LIBODBCHDB SO][HDBODBC] Connection not open;-10807 Connection down: [89013] Socket closed by peer {***.**.*.**:***** -> ***.**.***.**:***** TenantName:(none) SiteVolumeID:1:3 SiteType:PRIMARY ConnectionID:****** SessionID:************}
          <SQL> 'SELECT DISTINCT \"po_id\", ***CENSORED***'"
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))

  msg <- "`parse_database_error()` will not {be able to parse this}, but it should still be successfully rethrown as-is."
  expect_snapshot(error = TRUE, rethrow_database_error(msg, call = NULL))
})

test_that("set_database_error_names() works (#840)", {
  expect_equal(
    set_database_error_names(c("unnamed", "vector")),
    c(x = "unnamed", `*` = "vector")
  )
  expect_equal(set_database_error_names("unnamed scalar"), c(x = "unnamed scalar"))
  expect_equal(
    set_database_error_names(c("i" = "partially", "named")),
    c(i = "partially", `*` = "named")
  )
  expect_equal(
    set_database_error_names(c("partially", "i" = "named")),
    c(x = "partially", i = "named")
  )
  expect_equal(set_database_error_names(c("i" = "named")), c(i = "named"))
})

test_that("set_odbcsysini() works (#791)", {
  skip_on_cran()
  skip_if(is_windows())

  expect_false(identical(Sys.getenv("ODBCSYSINI"), ""))
})

test_that("check_row.names()", {
  skip_if_no_unixodbc()
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    dbWriteTable(con, "boopery", data.frame(bop = 1), row.names = c("no", "way"))
  )
})

test_that("check_field.types()", {
  skip_if_no_unixodbc()
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    dbWriteTable(con, "boopery", data.frame(bop = 1), field.types = "numeric")
  )
})

test_that("check_attributes()", {
  skip_if_no_unixodbc()
  expect_snapshot(
    error = TRUE,
    con <- test_con("SQLITE", attributes = list(boop = "bop"))
  )

  expect_snapshot(
    error = TRUE,
    con <- test_con("SQLITE", attributes = list(boop = "bop", beep = "boop"))
  )
})

test_that("configure_simba() returns early on windows", {
  local_mocked_bindings(is_macos = function() {FALSE})

  expect_equal(configure_simba(), NULL)
})

test_that("configure_simba() errors informatively on failure to install unixODBC", {
  local_mocked_bindings(
    is_macos = function() {TRUE},
    locate_install_unixodbc = function() {character(0)}
  )

  expect_snapshot(configure_simba(), error = TRUE)
})

test_that("configure_simba() calls configure_unixodbc_simba() (#835)", {
  skip_if_not(is_macos())
  local_mocked_bindings(
    locate_install_unixodbc = function() "hey",
    configure_unixodbc_simba = function(...) TRUE
  )

  expect_true(configure_simba(list(path = "example")))
})

test_that("locate_install_unixodbc() returns reasonable values", {
  skip_if(!is_macos())
  skip_if(!has_unixodbc(), "odbcinst not available.")

  # odbc_config / pkg-config cflags point to nonexistent files on CRAN (#903)
  skip_on_cran()

  res <- locate_install_unixodbc()

  expect_true(file.exists(res[1]))
  expect_true(grepl("(\\.dylib|\\.a)$", res[1]))
})

test_that("databricks() errors informatively when spark ini isn't writeable", {
  local_mocked_bindings(is_writeable = function(path) {FALSE})
  expect_snapshot(
    write_simba_lines("", ".", ".", call2("databricks")),
    error = TRUE
  )
})

test_that("driver_dir(...) returns reasonable values", {
  path <- "/some/path/driver.so"
  local_mocked_bindings(odbcListDrivers = function() {
    data.frame(name = "OG Driver", attribute = "Driver",
      value = path, drop = FALSE)
  })
  expect_equal(driver_dir("OG Driver"), "/some/path")
  expect_equal(driver_dir(path), "/some/path")
})

test_that("spark_simba_config() returns reasonable values", {
  simba_spark_ini <- "some/folder/simba.sparkodbc.ini"
  withr::local_envvar(SIMBASPARKINI = simba_spark_ini)
  expect_equal(spark_simba_config(""), simba_spark_ini)
})

test_that("configure_unixodbc_simba() writes reasonable entries", {
  unixodbc_install_path <- "libodbcinst.dylib"
  spark_config_path <- "simba.sparkodbc.ini"

  withr::local_file(spark_config_path)

  # neither of the relevant fields already there:
  writeLines(
    c("some=entries", "not=relevant"),
    con = spark_config_path
  )

  expect_snapshot(configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "warn"
  ))
  configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "modify"
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

  # both of the relevant fields are already there
  # but point to incorrect values
  writeLines(
    c("some=entries",
      "not=relevant",
      "ODBCInstLib=somewhere.dylib",
      "DriverManagerEncoding=UTF-8"),
    con = spark_config_path
  )

  expect_snapshot(configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "warn"
  ))
  res <- configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "modify"
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

  # One entry correct, other incorrect
  # expect warning with single suggestion
  # when action is "warn"
  writeLines(
    c("some=entries",
      "not=relevant",
      "ODBCInstLib=libodbcinst.dylib",
      "DriverManagerEncoding=UTF-32"),
    con = spark_config_path
  )

  expect_snapshot(configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "warn"
  ))
  res <- configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "modify"
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

  expect_snapshot(configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "warn"
  ))
  configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "modify"
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

  # Finally, a good config
  writeLines(
    c("some=entries",
      "not=relevant",
      "ODBCInstLib=libodbcinst.dylib",
      "DriverManagerEncoding=UTF-16"),
    con = spark_config_path
  )

  expect_no_warning(configure_unixodbc_simba(
    unixodbc_install = unixodbc_install_path,
    simba_config = spark_config_path,
    action = "warn"
  ))
})
