#' Driver for an ODBC database.
#'
#' @keywords internal
#' @export
#' @import DBI
#' @import methods
setClass("ODBConnectDriver", contains = "DBIDriver")

#' @export
#' @rdname ODBConnectDriver-class
setMethod("dbUnloadDriver", "ODBConnectDriver", function(drv, ...) {
  TRUE
})

#' @export
#' @rdname ODBConnectDriver-class
setMethod("show", "ODBConnectDriver", function(object) {
  cat("<ODBCDriver>\n")
})

#' @export
#' @rdname ODBConnectDriver-class
setMethod("dbGetInfo", "ODBConnectDriver", function(dbObj, what = "", ...) {
  cat("<ODBConnectDriver>\n")
})

#' @export
odbconnect <- function() {
  new("ODBConnectDriver")
}

#' @include odbconnect.R
NULL

#' DBI methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package.
#' @name DBI
NULL

#' Odbconnect driver
#'
#' TBD.
#'
#' @export
#' @import methods DBI
#' @examples
#' \dontrun{
#' #' library(DBI)
#' ROdbconnect::Odbconnect()
#' }
Odbconnect <- function() {
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
#' @export
setMethod(
  "dbConnect", "OdbconnectDriver",
  function(drv, ...) {
    OdbconnectConnection()
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
    # rstats-db/DBI#70
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
