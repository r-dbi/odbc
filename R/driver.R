#' Driver for an ODBC database.
#'
#' @keywords internal
#' @export
#' @import DBI
#' @import methods
setClass("ODBConnectDriver", contains = "DBIDriver")

#' @export
#' @rdname ODBC-class
setMethod("dbUnloadDriver", "ODBConnectDriver", function(drv, ...) {
  TRUE
})

#' @export
#' @rdname ODBC-class
setMethod("show", "ODBConnectDriver", function(object) {
  cat("<ODBCDriver>\n")
})

#' @export
#' @rdname ODBC-class
setMethod("dbGetInfo", "ODBConnectDriver", function(dbObj, what = "", ...) {
  cat("<ODBConnectDriver>\n")
})

#' @export
odbconnect <- function() {
  new("ODBConnectDriver")
}
