test_that("show method prints only host if no user is defined", {
  con <- new("OdbcConnection")
  local_mocked_bindings(
    dbGetInfo = function(x) c(servername = "localhost", username = "", dbname = "", dbms.name = "", db.version = ""),
    dbIsValid = function(x) TRUE
  )

  expect_snapshot(con)
})

test_that("show method prints DISCONNECTED if not valid", {
  con <- new("OdbcConnection")
  local_mocked_bindings(
    dbGetInfo = function(x) c(servername = "localhost", username = "", dbname = "", dbms.name = "", db.version = ""),
    dbIsValid = function(x) FALSE
  )
  expect_snapshot(con)
})

test_that("show method does not print server if it is not available", {
  con <- new("OdbcConnection")
  local_mocked_bindings(
    dbGetInfo = function(x) c(servername = "", username = "", dbname = "", dbms.name = "", db.version = ""),
    dbIsValid = function(x) TRUE
  )
  expect_snapshot(con)
})

test_that("dbQuoteIdentifier() errors informatively", {
  skip_if_no_unixodbc()
  con <- test_con("SQLITE")

  expect_snapshot(
    error = TRUE,
    dbQuoteIdentifier(con, NA_character_)
  )
})

test_that("dbConnect() errors informatively without unixODBC (#782)", {
  skip_on_os("windows")
  local_mocked_bindings(
    locate_install_unixodbc = function(...) {character()}
  )
  expect_snapshot(error = TRUE, test_con("SQLITE"), variant = Sys.info()[["sysname"]])
})
