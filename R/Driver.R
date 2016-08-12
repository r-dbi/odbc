#' @include odbconnect.R
NULL

#' DBI methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package.
#' @name DBI
NULL

#' Odbconnect driver
#'
#' Driver for an ODBC database.
#'
#' @export
#' @import methods DBI
#' @examples
#' \dontrun{
#' #' library(DBI)
#' Odbconnect::Odbconnect()
#' }
odbconnect <- function() {
  new("OdbconnectDriver")
}

#' @rdname DBI
#' @export
setClass("OdbconnectDriver", contains = "DBIDriver")

#' @rdname DBI
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbconnectDriver",
  function(object) {
    cat("<OdbconnectDriver>\n")
    # TODO: Print more details
  })

#' @rdname DBI
#' @inheritParams DBI::dbConnect
#' @param dsn The ODBC dsn to connect to.
#' @param ... Additional ODBC named arguments to use in the connection, these
#' will be joined together to form the connection string.
#' @export
setMethod(
  "dbConnect", "OdbconnectDriver",
  function(drv, dsn = NULL, ...) {
    OdbconnectConnection(dsn = dsn, ...)
  }
)

#' @rdname DBI
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbconnectDriver",
  function(dbObj, obj, ...) {
    # Optional: Can remove this if all data types conform to SQL-92
    tryCatch(
      getMethod("dbDataType", "DBIObject", asNamespace("DBI"))(dbObj, obj, ...),
      error = function(e) testthat::skip("Not yet implemented: dbDataType(Driver)"))
  })

#' @rdname DBI
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbconnectDriver", "list"),
  function(dbObj, obj, ...) {
    testthat::skip("Not yet implemented: dbDataType(Driver, list)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbconnectDriver",
  function(dbObj) {
    testthat::skip("Not yet implemented: dbIsValid(Driver)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectDriver",
  function(dbObj, ...) {
    testthat::skip("Not yet implemented: dbGetInfo(Driver)")
  })
