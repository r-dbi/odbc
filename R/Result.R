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
    if (!dbIsValid(res)) {
      warning("Result already cleared")
    } else {
      result_release(res@ptr)
    }
    TRUE
  })

#' @rdname DBI
#' @inheritParams DBI::dbFetch
#' @export
setMethod(
  "dbFetch", "OdbconnectResult",
  function(res, n = -1, ...) {
    result_fetch(res@ptr, n, ...)
  })

#' @rdname DBI
#' @inheritParams DBI::dbHasCompleted
#' @export
setMethod(
  "dbHasCompleted", "OdbconnectResult",
  function(res, ...) {
    result_completed(res@ptr)
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
    result_active(dbObj@ptr)
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetStatement
#' @export
setMethod(
  "dbGetStatement", "OdbconnectResult",
  function(res, ...) {
    res@statement
  })

#' @rdname DBI
#' @inheritParams DBI::dbColumnInfo
#' @export
setMethod(
  "dbColumnInfo", "OdbconnectResult",
  function(res, ...) {
    connection_sql_columns(res@connection@ptr, ...)
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetRowCount
#' @export
setMethod(
  "dbGetRowCount", "OdbconnectResult",
  function(res, ...) {
    result_row_count(res@ptr)
  })

#' @rdname DBI
#' @inheritParams DBI::getRowsAffected
#' @export
setMethod(
  "dbGetRowsAffected", "OdbconnectResult",
  function(res, ...) {
    result_rows_affected(res@ptr)
  })

#' @rdname DBI
#' @inheritParams DBI::dbBind
#' @export
setMethod(
  "dbBind", "OdbconnectResult",
  function(res, params, ...) {
    result_bind(res@ptr, params)
    TRUE
  })
