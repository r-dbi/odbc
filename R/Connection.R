#' @include Driver.R
NULL

OdbconnectConnection <- function(dsn = NULL, quote = "\"", ...) {
  args <- list(...)
  stopifnot(all(has_names(args)))

  if (!is.null(dsn)) {
    args[["dsn"]] <- dsn
  }
  connection_string <- paste(collapse = ";", sep = "=", names(args), args)
  ptr <- odbconnect_connect(connection_string)
  new("OdbconnectConnection", ptr = ptr, quote = quote)
}

#' @rdname DBI
#' @export
setClass(
  "OdbconnectConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    quote = "character"
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
    connection_valid(dbObj@ptr)
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

    connection_release(conn@ptr)
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
    get_data_type(obj)
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
    x <- gsub(conn@quote, paste0(conn@quote, conn@quote), x, fixed = TRUE)
    DBI::SQL(paste(conn@quote, x, conn@quote, sep = ""))
  })

#' @rdname DBI
#' @inheritParams DBI::dbListTables
#' @export
setMethod(
  "dbListTables", "OdbconnectConnection",
  function(conn) {
    connection_sql_tables(conn@ptr)[["TABLE_NAME"]]
  })

#' @rdname DBI
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod(
  "dbExistsTable", c("OdbconnectConnection", "character"),
  function(conn, name) {
    name %in% dbListTables(conn)
  })

#' @rdname DBI
#' @inheritParams DBI::dbListFields
#' @export
setMethod(
  "dbListFields", c("OdbconnectConnection", "character"),
  function(conn, name) {
    connection_sql_columns(conn@ptr, table_name = name)[["COLUMN_NAME"]]
  })

#' @rdname DBI
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod(
  "dbRemoveTable", c("OdbconnectConnection", "character"),
  function(conn, name) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  })

#' @rdname DBI
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectConnection",
  function(dbObj, ...) {
    connection_info(dbObj@ptr)
  })

#' @rdname DBI
#' @inheritParams DBI::dbBegin
#' @export
setMethod(
  "dbBegin", "OdbconnectConnection",
  function(conn) {
    dbGetQuery(conn, "BEGIN")
    TRUE
  })

#' @rdname DBI
#' @inheritParams DBI::dbCommit
#' @export
setMethod(
  "dbCommit", "OdbconnectConnection",
  function(conn) {
    connection_commit(conn@ptr)
    TRUE
  })

#' @rdname DBI
#' @inheritParams DBI::dbRollback
#' @export
setMethod(
  "dbRollback", "OdbconnectConnection",
  function(conn) {
    connection_rollback(conn@ptr)
    TRUE
  })

get_data_type <- function(obj) {
  if (is.factor(obj)) return("TEXT")
  if (is(obj, "POSIXct")) return("TIMESTAMP")
  if (is(obj, "Date")) return("DATE")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "TEXT",
    logical = "INTEGER",
    #list = "BLOB",
    stop("Unsupported type", call. = FALSE)
  )
}
