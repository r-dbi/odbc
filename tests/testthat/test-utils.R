test_that("parse_size works", {
  expect_error(parse_size("foo"), "Must be a positive integer")
  expect_error(parse_size(TRUE), "Must be a positive integer")
  expect_error(parse_size(0), "Must be a positive integer")
  expect_error(parse_size(-1), "Must be a positive integer")
  expect_error(parse_size(-.1), "Must be a positive integer")
  expect_error(parse_size(.1), "Must be a positive integer")
  expect_error(parse_size("0"), "Must be a positive integer")
  expect_error(parse_size("1"), "Must be a positive integer")
  expect_error(parse_size(Inf), "Must be a positive integer")
  expect_error(parse_size(NULL), "Must be a positive integer")
  expect_error(parse_size(1:2), "Must be a positive integer")
  expect_error(parse_size(numeric()), "Must be a positive integer")
  expect_error(parse_size(integer()), "Must be a positive integer")

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

test_that("configure_spark() returns early on windows", {
  local_mocked_bindings(is_windows = function() {TRUE})

  res <- configure_spark()

  expect_equal(res, NULL)
})

test_that("configure_spark() errors informatively on failure to install unixODBC", {
  local_mocked_bindings(
    install_unixodbc_libs = function() {stop("Nope!")},
    is_windows = function() {FALSE},
    locate_install_unixodbc = function() {character(0)},
    has_unixodbc = function() {FALSE}
  )

  expect_snapshot(configure_spark(), error = TRUE)
})

test_that("locate_install_unixodbc() returns reasonable values", {
  skip_on_os("windows")
  skip_if(!has_unixodbc(), "odbcinst not available.")

  res <- locate_install_unixodbc()

  # quick, known-failing tests to see what the values are on Actions
  expect_equal("boop", res)
  expect_equal("boop", Sys.getenv("DYLD_LIBRARY_PATH"))
  expect_equal("boop", Sys.getenv("LD_LIBRARY_PATH"))

  expect_true(file.exists(res[1]))
  expect_true(grepl("\\.dylib", res[1]))
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
