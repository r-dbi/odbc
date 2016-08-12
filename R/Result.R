#' @include Connection.R
NULL

OdbconnectResult <- function(connection, statement) {
  ptr <- query(connection@ptr, statement)
  new("OdbconnectResult", connection = connection, statement = statement, ptr = ptr)
}

#' @rdname DBI
#' @export
setClass(
  "OdbconnectResult",
  contains = "DBIResult",
  slots = list(
    connection = "OdbconnectConnection",
    statement = "character",
    ptr = "externalptr"
  )
)

#' @rdname DBI
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbconnectResult",
  function(object) {
    cat("<OdbconnectResult>\n")
    # TODO: Print more details
  })

#' @rdname DBI
#' @inheritParams DBI::dbClearResult
#' @export
setMethod(
  "dbClearResult", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbClearResult(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbFetch
#' @export
setMethod(
  "dbFetch", "OdbconnectResult",
  function(res, n = -1, ...) {
    testthat::skip("Not yet implemented: dbFetch(Result)")
    #fetch(res@ptr)
  })

#' @rdname DBI
#' @inheritParams DBI::dbHasCompleted
#' @export
setMethod(
  "dbHasCompleted", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbHasCompleted(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectResult",
  function(dbObj, ...) {
    # Optional
    getMethod("dbGetInfo", "DBIResult", asNamespace("DBI"))(dbObj, ...)
  })

#' @rdname DBI
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbconnectResult",
  function(dbObj) {
    testthat::skip("Not yet implemented: dbIsValid(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetStatement
#' @export
setMethod(
  "dbGetStatement", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbGetStatement(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbColumnInfo
#' @export
setMethod(
  "dbColumnInfo", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbColumnInfo(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetRowCount
#' @export
setMethod(
  "dbGetRowCount", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbGetRowCount(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::getRowsAffected
#' @export
setMethod(
  "dbGetRowsAffected", "OdbconnectResult",
  function(res, ...) {
    testthat::skip("Not yet implemented: dbGetRowsAffected(Result)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbBind
#' @export
setMethod(
  "dbBind", "OdbconnectResult",
  function(res, params, ...) {
    testthat::skip("Not yet implemented: dbBind(Result)")
  })
