#' ODBConnect results class.
#'
#' @keywords internal
#' @export
setClass("ODBConnectResult",
  contains = "DBIResult",
  slots = list(ptr = "externalptr")
)

#' Send a query to ODBConnect.
#'
#' @export
#' @examples
#' # This is another good place to put examples
setMethod("dbSendQuery", "ODBConnectConnection", function(conn, statement, buffer_size = 4096, ...) {
  ptr <- query(conn@ptr, statement, buffer_size)
  new("ODBConnectResult", ptr = ptr)
})


#' Retrieve records from ODBConnect query
#' @export
setMethod("dbFetch", "ODBConnectResult", function(res, ...) {
  fetch(res@ptr)
})

#' @export
setMethod("dbHasCompleted", "ODBConnectResult", function(res, ...) {
  has_completed(res@ptr)
})

#' @include Connection.R
NULL

OdbconnectResult <- function(connection, statement) {
  # TODO: Initialize result
  new("OdbconnectResult", connection = connection, statement = statement)
}

#' @rdname DBI
#' @export
setClass(
  "OdbconnectResult",
  contains = "DBIResult",
  slots = list(
    connection = "OdbconnectConnection",
    statement = "character"
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
