skip_unless_has_test_db <- function(expr) {
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    return(skip("On CRAN"))
  }

  # Failing database connection should fail the test in DBItest backends
  if (nzchar(Sys.getenv("DBITEST_BACKENDS"))) {
    con <- DBItest:::connect(expr)
    DBI::dbDisconnect(con)
    TRUE
  } else {
    tryCatch({
      con <- DBItest:::connect(expr)
      DBI::dbDisconnect(con)
      TRUE
    }, error = function(e) {
      skip(paste0("Test database not available:\n'", conditionMessage(e), "'"))
    })
  }
}
