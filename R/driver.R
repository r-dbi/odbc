#' Driver for an ODBC database.
#'
#' @keywords internal
#' @export
#' @import DBI
#' @import methods
setClass("ODBCDriver", contains = "DBIDriver")

#' @export
#' @rdname ODBC-class
setMethod("dbUnloadDriver", "ODBCDriver", function(drv, ...) {
  TRUE
})

#' @export
#' @rdname ODBC-class
setMethod("show", "ODBCDriver", function(object) {
  cat("<ODBCDriver>\n")
})

#' @export
#' @rdname ODBC-class
setMethod("dbGetInfo", "ODBCDriver", function(dbObj, what = "", ...) {
  cat("<ODBCDriver>\n")
})

#' @export
odbconnect <- function() {
  new("ODBCDriver")
}

#odbconnect()
