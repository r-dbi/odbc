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
