#' @include Driver.R
NULL

OdbconnectConnection <- function(dsn = NULL, ...) {
  args <- list(...)
  stopifnot(all(has_names(args)))

  if (!is.null(dsn)) {
    args[["dsn"]] <- dsn
  }
  connection_string <- paste(collapse = ";", sep = "=", names(args), args)
  ptr <- connect(connection_string)
  new("OdbconnectConnection", ptr = ptr)
}

#' @rdname DBI
#' @export
setClass(
  "OdbconnectConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr"
  )
)

#' @rdname DBI
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbconnectConnection",
  function(object) {
    cat("<OdbconnectConnection>\n")
    # TODO: Print more details
  })

#' @rdname DBI
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbconnectConnection",
  function(dbObj) {
    testthat::skip("Not yet implemented: dbIsValid(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbDisconnect
#' @export
setMethod(
  "dbDisconnect", "OdbconnectConnection",
  function(conn) {
    if (!dbIsValid(conn)) {
      warning("Connection already closed.", call. = FALSE)
    }

    # TODO: Free resources
    TRUE
  })

#' @rdname DBI
#' @inheritParams DBI::dbSendQuery
#' @export
setMethod(
  "dbSendQuery", c("OdbconnectConnection", "character"),
  function(conn, statement, ...) {
    OdbconnectResult(connection = conn, statement = statement)
  })

#' @rdname DBI
#' @inheritParams DBI::dbSendStatement
#' @export
setMethod(
  "dbSendStatement", c("OdbconnectConnection", "character"),
  function(conn, statement, ...) {
    OdbconnectResult(connection = conn, statement = statement)
  })

#' @rdname DBI
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbconnectConnection",
  function(dbObj, obj, ...) {
    tryCatch(
      getMethod("dbDataType", "DBIObject", asNamespace("DBI"))(dbObj, obj, ...),
      error = function(e) testthat::skip("Not yet implemented: dbDataType(Connection)"))
  })

#' @rdname DBI
#' @inheritParams DBI::dbQuoteString
#' @export
setMethod(
  "dbQuoteString", c("OdbconnectConnection", "character"),
  function(conn, x, ...) {
    # Optional
    getMethod("dbQuoteString", c("DBIConnection", "character"), asNamespace("DBI"))(conn, x, ...)
  })

#' @rdname DBI
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod(
  "dbQuoteIdentifier", c("OdbconnectConnection", "character"),
  function(conn, x, ...) {
    # Optional
    getMethod("dbQuoteIdentifier", c("DBIConnection", "character"), asNamespace("DBI"))(conn, x, ...)
  })

#' @rdname DBI
#' @inheritParams DBI::dbWriteTable
#' @param overwrite Allow overwriting the destination table. Cannot be
#'   \code{TRUE} if \code{append} is also \code{TRUE}.
#' @param append Allow appending to the destination table. Cannot be
#'   \code{TRUE} if \code{overwrite} is also \code{TRUE}.
#' @export
setMethod(
  "dbWriteTable", c("OdbconnectConnection", "character", "data.frame"),
  function(conn, name, value, overwrite=FALSE, append=FALSE, ...) {
    testthat::skip("Not yet implemented: dbWriteTable(Connection, character, data.frame)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbReadTable
#' @export
setMethod(
  "dbReadTable", c("OdbconnectConnection", "character"),
  function(conn, name) {
    testthat::skip("Not yet implemented: dbReadTable(Connection, character)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbListTables
#' @export
setMethod(
  "dbListTables", "OdbconnectConnection",
  function(conn) {
    testthat::skip("Not yet implemented: dbListTables(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod(
  "dbExistsTable", c("OdbconnectConnection", "character"),
  function(conn, name) {
    testthat::skip("Not yet implemented: dbExistsTable(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbListFields
#' @export
setMethod(
  "dbListFields", c("OdbconnectConnection", "character"),
  function(conn, name) {
    testthat::skip("Not yet implemented: dbListFields(Connection, character)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod(
  "dbRemoveTable", c("OdbconnectConnection", "character"),
  function(conn, name) {
    testthat::skip("Not yet implemented: dbRemoveTable(Connection, character)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectConnection",
  function(dbObj, ...) {
    testthat::skip("Not yet implemented: dbGetInfo(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbBegin
#' @export
setMethod(
  "dbBegin", "OdbconnectConnection",
  function(conn) {
    testthat::skip("Not yet implemented: dbBegin(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbCommit
#' @export
setMethod(
  "dbCommit", "OdbconnectConnection",
  function(conn) {
    testthat::skip("Not yet implemented: dbCommit(Connection)")
  })

#' @rdname DBI
#' @inheritParams DBI::dbRollback
#' @export
setMethod(
  "dbRollback", "OdbconnectConnection",
  function(conn) {
    testthat::skip("Not yet implemented: dbRollback(Connection)")
  })
