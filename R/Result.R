#' @include Connection.R
NULL

#' Odbc Result Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcResult objects.
#' @name OdbcResult
#' @docType methods
NULL

OdbcResult <- function(connection, statement, ...) {
  direct <- isTRUE(as.logical(list(...)[['direct']]))
  ptr <- new_result(connection@ptr, statement, direct)
  new("OdbcResult", connection = connection, statement = statement, direct = direct, ptr = ptr)
}

#' @rdname OdbcResult
#' @export
setClass(
  "OdbcResult",
  contains = "DBIResult",
  slots = list(
    connection = "OdbcConnection",
    statement = "character",
    direct = "logical",
    ptr = "externalptr"
  )
)

#' @rdname OdbcResult
#' @inheritParams DBI::dbClearResult
#' @export
setMethod(
  "dbClearResult", "OdbcResult",
  function(res, ...) {
    if (!dbIsValid(res)) {
      warning("Result already cleared")
    } else {
      result_release(res@ptr)
    }
    invisible(TRUE)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbFetch
#' @export
setMethod(
  "dbFetch", "OdbcResult",
  function(res, n = -1, ...) {
    result_fetch(res@ptr, n)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbHasCompleted
#' @export
setMethod(
  "dbHasCompleted", "OdbcResult",
  function(res, ...) {
    result_set <- isTRUE(as.logical(list(...)[['result_set']]))
    result_completed(res@ptr, result_set)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbcResult",
  function(dbObj, ...) {
    result_active(dbObj@ptr)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbGetStatement
#' @export
setMethod(
  "dbGetStatement", "OdbcResult",
  function(res, ...) {
    if (!dbIsValid(res)) {
      stop("Result already cleared", call. = FALSE)
    }
    res@statement
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbColumnInfo
#' @export
setMethod(
  "dbColumnInfo", "OdbcResult",
  function(res, ...) {
    result_column_info(res@ptr, ...)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbGetRowCount
#' @export
setMethod(
  "dbGetRowCount", "OdbcResult",
  function(res, ...) {
    result_row_count(res@ptr)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbGetRowsAffected
#' @export
setMethod(
  "dbGetRowsAffected", "OdbcResult",
  function(res, ...) {
    result_rows_affected(res@ptr)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbBind
#' @export
setMethod(
  "dbBind", "OdbcResult",
  function(res, params, ...) {
    result_bind(res@ptr, as.list(params))
    invisible(res)
  })
