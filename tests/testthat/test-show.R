context("show")

test_that("show method prints only host if no user is defined", {
  con <- new("OdbcConnection")
  with_mock(
    `DBI::dbGetInfo` = function(x) c(servername = "localhost", username = "", dbname = "", dbms.name = "", db.version = ""),
    `DBI::dbIsValid` = function(x) TRUE,
    {
      expect_output(show(con), " localhost")
    })
})

test_that("show method prints DISCONNECTED if not valid", {
  con <- new("OdbcConnection")
  with_mock(
    `DBI::dbGetInfo` = function(x) c(servername = "localhost", username = "", dbname = "", dbms.name = "", db.version = ""),
    `DBI::dbIsValid` = function(x) FALSE,
    {
      expect_output(show(con), "  DISCONNECTED")
    })
})

test_that("show method does not print server if it is not available", {
  con <- new("OdbcConnection")
  with_mock(
    `DBI::dbGetInfo` = function(x) c(servername = "", username = "", dbname = "", dbms.name = "", db.version = ""),
    `DBI::dbIsValid` = function(x) TRUE,
    {
      expect_output(show(con), "<OdbcConnection>$")
    })
})
