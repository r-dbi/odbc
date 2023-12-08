#' @include Connection.R
NULL

#' Odbc Result Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcResult objects.
#' @name OdbcResult
#' @docType methods
NULL

OdbcResult <- function(connection, statement, params = NULL, immediate = FALSE) {
  if (nzchar(connection@encoding)) {
    statement <- enc2iconv(statement, connection@encoding)
  }
  ptr <- new_result(connection@ptr, statement, immediate)
  res <- new("OdbcResult", connection = connection, statement = statement, ptr = ptr)

  if (!is.null(params)) {
    on.exit(dbClearResult(res))
    dbBind(res, params = params)
    on.exit(NULL)
  }
  res
}

#' @rdname OdbcResult
#' @keywords internal
#' @export
setClass(
  "OdbcResult",
  contains = "DBIResult",
  slots = list(
    connection = "OdbcConnection",
    statement = "character",
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
    }
    result_release(res@ptr)
    invisible(TRUE)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbFetch
#' @export
setMethod(
  "dbFetch", "OdbcResult",
  function(res, n = -1, ...) {
    n <- check_n(n)
    result_fetch(res@ptr, n)
  })

#' @rdname OdbcResult
#' @inheritParams DBI::dbHasCompleted
#' @export
setMethod(
  "dbHasCompleted", "OdbcResult",
  function(res, ...) {
    result_completed(res@ptr)
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
    result_column_info(res@ptr)
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
#' @inheritParams DBI-tables
#' @export
setMethod(
  "dbBind", "OdbcResult",
  function(res, params, ..., batch_rows = getOption("odbc.batch_rows", NA)) {
    params <- as.list(params)
    if (length(params) == 0) {
      return(invisible(res))
    }

    if (is.na(batch_rows)) {
      batch_rows <- length(params[[1]])
    }

    batch_rows <- parse_size(batch_rows)

    result_bind(res@ptr, params, batch_rows)
    invisible(res)
  })
