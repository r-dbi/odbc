#' @include Driver.R
NULL

#' Odbconnect Connection Methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package
#' for OdbconnectConnection objects.
#' @name OdbconnectConnection
NULL

OdbconnectConnection <- function(dsn = NULL, ..., driver = NULL, server = NULL, database = NULL, uid = NULL, pwd = NULL) {
  args <- c(dsn = dsn, driver = driver, server = server, database = database, uid = uid, pwd = pwd, list(...))
  stopifnot(all(has_names(args)))

  connection_string <- paste(collapse = ";", sep = "=", names(args), args)
  ptr <- odbconnect_connect(connection_string)
  quote <- connection_quote(ptr)

  # a-z A-Z, 0-9 and _ are always valid, other characters than can be are
  # connection specific and returned by connection_special
  valid_characters <- c(letters, LETTERS, 0:9, "_", connection_special(ptr))

  info <- connection_info(ptr)
  class(info) <- c(info$dbms.name, "list")

  new("OdbconnectConnection", ptr = ptr, quote = quote, valid_characters = valid_characters, info = info)
}

#' @rdname OdbconnectConnection
#' @export
setClass(
  "OdbconnectConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    quote = "character",
    valid_characters = "character",
    info = "ANY"
  )
)

#' @rdname OdbconnectConnection
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbconnectConnection",
  function(object) {
    info <- dbGetInfo(object)

    cat(sep = "", "<OdbconnectConnection>",
      if (nzchar(info[["servername"]])) {
        paste0(" ",
          if (nzchar(info[["username"]])) paste0(info[["username"]], "@"),
          info[["servername"]], "\n")
      },
      if (!dbIsValid(object)) {
        "  DISCONNECTED\n"
      } else {
        paste0(collapse = "",
          if (nzchar(info[["dbname"]])) {
            paste0("  Database: ", info[["dbname"]], "\n")
          },
          if (nzchar(info[["dbms.name"]]) && nzchar(info[["db.version"]])) {
            paste0("  ", info[["dbms.name"]], " ", "Version: ", info[["db.version"]], "\n")
          },
          NULL)
      })
})

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbconnectConnection",
  function(dbObj, ...) {
    connection_valid(dbObj@ptr)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbDisconnect
#' @export
setMethod(
  "dbDisconnect", "OdbconnectConnection",
  function(conn, ...) {
    if (!dbIsValid(conn)) {
      warning("Connection already closed.", call. = FALSE)
    }

    connection_release(conn@ptr)
    TRUE
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbSendQuery
#' @export
setMethod(
  "dbSendQuery", c("OdbconnectConnection", "character"),
  function(conn, statement, ...) {
    res <- OdbconnectResult(connection = conn, statement = statement)
    result_execute(res@ptr)
    res
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbSendStatement
#' @export
setMethod(
  "dbSendStatement", c("OdbconnectConnection", "character"),
  function(conn, statement, ...) {
    res <- OdbconnectResult(connection = conn, statement = statement)
    result_execute(res@ptr)
    res
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbconnectConnection",
  function(dbObj, obj, ...) {
    get_data_type(dbObj@info, obj)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbQuoteString
#' @export
setMethod(
  "dbQuoteString", c("OdbconnectConnection", "character"),
  function(conn, x, ...) {
    # Optional
    getMethod("dbQuoteString", c("DBIConnection", "character"), asNamespace("DBI"))(conn, x, ...)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod(
  "dbQuoteIdentifier", c("OdbconnectConnection", "character"),
  function(conn, x, ...) {
    x <- gsub(conn@quote, paste0(conn@quote, conn@quote), x, fixed = TRUE)
    DBI::SQL(paste(conn@quote, encodeString(x), conn@quote, sep = ""))
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbListTables
#' @export
setMethod(
  "dbListTables", "OdbconnectConnection",
  function(conn, ...) {
    connection_sql_tables(conn@ptr, ...)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod(
  "dbExistsTable", c("OdbconnectConnection", "character"),
  function(conn, name, ...) {
    name %in% dbListTables(conn)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbListFields
#' @export
setMethod(
  "dbListFields", c("OdbconnectConnection", "character"),
  function(conn, name, ...) {
    connection_sql_columns(conn@ptr, table_name = name)[["name"]]
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod(
  "dbRemoveTable", c("OdbconnectConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectConnection",
  function(dbObj, ...) {
    connection_info(dbObj@ptr)
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbGetQuery
#' @export
setMethod("dbGetQuery", signature("OdbconnectConnection", "character"),
  function(conn, statement, ...) {
    rs <- dbSendQuery(conn, statement, ...)
    on.exit(dbClearResult(rs))

    df <- dbFetch(rs, n = -1, ...)

    if (!dbHasCompleted(rs)) {
      warning("Pending rows", call. = FALSE)
    }

    df
  }
)

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbBegin
#' @export
setMethod(
  "dbBegin", "OdbconnectConnection",
  function(conn, ...) {
    connection_begin(conn@ptr)
    TRUE
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbCommit
#' @export
setMethod(
  "dbCommit", "OdbconnectConnection",
  function(conn, ...) {
    connection_commit(conn@ptr)
    TRUE
  })

#' @rdname OdbconnectConnection
#' @inheritParams DBI::dbRollback
#' @export
setMethod(
  "dbRollback", "OdbconnectConnection",
  function(conn, ...) {
    connection_rollback(conn@ptr)
    TRUE
  })

get_data_type <- function(info, obj, ...) UseMethod("get_data_type")

varchar_data_type <- function(x) {
  #size <- 2L^(floor(log2(max(nchar(as.character(x))))) + 1L)
  #paste0("VARCHAR(", size, ")")
  paste0("VARCHAR(255)")
}

get_data_type.default <- function(info, obj, ...) {
  if (is.factor(obj)) return(varchar_data_type(obj))
  if (is(obj, "POSIXct")) return("TIMESTAMP")
  if (is(obj, "Date")) return("DATE")
  if (is(obj, "blob")) return("BLOB")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = varchar_data_type(obj),
    logical = "SMALLINT",
    list = varchar_data_type(obj),
    stop("Unsupported type", call. = FALSE)
  )
}

get_data_type.MySQL <- function(info, obj, ...) {
  if (is.factor(obj)) return("TEXT")
  if (is(obj, "POSIXct")) return("DATETIME")
  if (is(obj, "Date")) return("DATE")
  if (is(obj, "blob")) return("BLOB")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE",
    character = "TEXT",
    logical = "TINYINT",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

get_data_type.PostgreSQL <- function(info, obj, ...) {
  if (is.factor(obj)) return("TEXT")
  if (is(obj, "POSIXct")) return("TIMESTAMP")
  if (is(obj, "Date")) return("DATE")
  if (is(obj, "blob")) return("bytea")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

`get_data_type.Microsoft SQL Server` <- function(info, obj, ...) {
  if (is.factor(obj)) return("varchar(max)")
  if (is(obj, "POSIXct")) return("datetime")
  if (is(obj, "Date")) return("date")
  if (is(obj, "blob")) return("varbinary(max)")

  switch(typeof(obj),
    integer = "int",
    double = "float",
    character = "varchar(max)",
    logical = "BIT",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}

`get_data_type.SQLite` <- function(info, obj, ...) {
  if (is.factor(obj)) return("TEXT")
  if (is(obj, "POSIXct")) return("NUMERIC")
  if (is(obj, "Date")) return("NUMERIC")
  if (is(obj, "blob")) return("BLOB")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "NUMERIC",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}
