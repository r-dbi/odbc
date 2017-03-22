skip_unless_has_test_db <- function(expr) {
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    return(skip("On CRAN"))
  }
  tryCatch({
    DBItest:::connect(expr)
    TRUE
  }, error = function(e) {
    skip(paste0("Test database not available:\n'", conditionMessage(e), "'"))
  })
}
