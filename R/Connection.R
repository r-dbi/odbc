#' @include Driver.R
NULL

#' Odbc Connection Methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package
#' for OdbcConnection objects.
#' @name OdbcConnection
NULL

OdbcConnection <- function(dsn = NULL, ..., timezone = "", driver = NULL, server = NULL, database = NULL, uid = NULL, pwd = NULL, .connection_string = NULL) {
  args <- c(dsn = dsn, driver = driver, server = server, database = database, uid = uid, pwd = pwd, list(...))
  stopifnot(all(has_names(args)))

  connection_string <- paste0(.connection_string, paste(collapse = ";", sep = "=", names(args), args))
  ptr <- odbc_connect(connection_string, timezone = timezone)
  quote <- connection_quote(ptr)

  info <- connection_info(ptr)
  class(info) <- c(info$dbms.name, "list")

  new("OdbcConnection", ptr = ptr, quote = quote, info = info)
}

#' @rdname OdbcConnection
#' @export
setClass(
  "OdbcConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    quote = "character",
    info = "ANY"
  )
)

#' @rdname OdbcConnection
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbcConnection",
  function(object) {
    info <- dbGetInfo(object)

    cat(sep = "", "<OdbcConnection>",
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

#' @rdname OdbcConnection
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbcConnection",
  function(dbObj, ...) {
    connection_valid(dbObj@ptr)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDisconnect
#' @export
setMethod(
  "dbDisconnect", "OdbcConnection",
  function(conn, ...) {
    if (!dbIsValid(conn)) {
      warning("Connection already closed.", call. = FALSE)
    }

    connection_release(conn@ptr)
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendQuery
#' @export
setMethod(
  "dbSendQuery", c("OdbcConnection", "character"),
  function(conn, statement, ...) {
    res <- OdbcResult(connection = conn, statement = statement)
    res
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendStatement
#' @export
setMethod(
  "dbSendStatement", c("OdbcConnection", "character"),
  function(conn, statement, ...) {
    res <- OdbcResult(connection = conn, statement = statement)
    res
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbcConnection",
  function(dbObj, obj, ...) {
    get_data_type(dbObj@info, obj)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteString
#' @export
setMethod(
  "dbQuoteString", c("OdbcConnection", "character"),
  function(conn, x, ...) {
    # Optional
    getMethod("dbQuoteString", c("DBIConnection", "character"), asNamespace("DBI"))(conn, x, ...)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod(
  "dbQuoteIdentifier", c("OdbcConnection", "character"),
  function(conn, x, ...) {
    if (nzchar(conn@quote)) {
      x <- gsub(conn@quote, paste0(conn@quote, conn@quote), x, fixed = TRUE)
    }
    DBI::SQL(paste(conn@quote, encodeString(x), conn@quote, sep = ""))
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbListTables
#' @export
setMethod(
  "dbListTables", "OdbcConnection",
  function(conn, ...) {
    connection_sql_tables(conn@ptr, ...)$table_name
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod(
  "dbExistsTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    name %in% dbListTables(conn)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbListFields
#' @export
setMethod(
  "dbListFields", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    connection_sql_columns(conn@ptr, table_name = name)[["name"]]
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod(
  "dbRemoveTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbcConnection",
  function(dbObj, ...) {
    connection_info(dbObj@ptr)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetQuery
#' @export
setMethod("dbGetQuery", signature("OdbcConnection", "character"),
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

#' @rdname OdbcConnection
#' @inheritParams DBI::dbBegin
#' @export
setMethod(
  "dbBegin", "OdbcConnection",
  function(conn, ...) {
    connection_begin(conn@ptr)
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbCommit
#' @export
setMethod(
  "dbCommit", "OdbcConnection",
  function(conn, ...) {
    connection_commit(conn@ptr)
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbRollback
#' @export
setMethod(
  "dbRollback", "OdbcConnection",
  function(conn, ...) {
    connection_rollback(conn@ptr)
    invisible(TRUE)
  })

get_data_type <- function(info, obj, ...) UseMethod("get_data_type")

varchar <- function(x, type = "varchar") {
  max_length <- max(nchar(as.character(x)), na.rm = TRUE)
  paste0(type, "(", max(255, max_length), ")")
}

varbinary <- function(x, type = "varbinary") {
  max_length <- max(lengths(x), na.rm = TRUE)
  paste0(type, "(", max(255, max_length), ")")
}

get_data_type.default <- function(info, obj, ...) {
  if (is.factor(obj)) return(varchar(obj))
  if (is(obj, "POSIXct")) return("TIMESTAMP")
  if (is(obj, "Date")) return("DATE")
  if (is(obj, "blob")) return("BLOB")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = varchar(obj),
    logical = "SMALLINT",
    list = varchar(obj),
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
  if (is.factor(obj)) return(varchar(obj))
  if (is(obj, "POSIXct")) return("datetime")
  if (is(obj, "Date")) return("date")
  if (is(obj, "blob")) return(varbinary(obj))

  switch(typeof(obj),
    integer = "int",
    double = "float",
    character = varchar(obj),
    logical = "BIT",
    list = varchar(obj),
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

#' List Available ODBC Drivers
#'
#' @return A data frame with three columns.
#' If a given driver does not have any attributes the last two columns will be
#' \code{NA}.
#' \describe{
#'   \item{name}{Name of the driver}
#'   \item{attribute}{Driver attribute name}
#'   \item{value}{Driver attribute value}
#' }
#' @export
list_drivers <- function() {
  res <- list_drivers_()
  res[res == ""] <- NA_character_
  res
}

#' List Available Data Source Names
#'
#' @return A data frame with two columns.
#' \describe{
#'   \item{name}{Name of the data source}
#'   \item{description}{Data Source description}
#' }
#' @export
list_data_sources <- function() {
  list_data_sources_()
}
