#' @rdname OdbcConnection
#' @keywords internal
#' @export
setClass(
  "OdbcConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    quote = "character",
    info = "ANY",
    encoding = "character"
  )
)


# TODO: show encoding, timezone, bigint mapping
#' @rdname OdbcConnection
#' @inheritParams methods::show
#' @export
setMethod("show", "OdbcConnection",
  function(object) {
    info <- dbGetInfo(object)

    cat(
      sep = "", "<OdbcConnection>",
      if (nzchar(info[["servername"]])) {
        paste0(
          " ",
          if (nzchar(info[["username"]])) paste0(info[["username"]], "@"),
          info[["servername"]], "\n"
        )
      },
      if (!dbIsValid(object)) {
        "  DISCONNECTED\n"
      } else {
        paste0(
          collapse = "",
          if (nzchar(info[["dbname"]])) {
            paste0("  Database: ", info[["dbname"]], "\n")
          },
          if (nzchar(info[["dbms.name"]]) && nzchar(info[["db.version"]])) {
            paste0("  ", info[["dbms.name"]], " ", "Version: ", info[["db.version"]], "\n")
          },
          NULL
        )
      }
    )
  }
)


#' @rdname OdbcConnection
#' @inheritParams DBI::dbIsValid
#' @export
setMethod("dbIsValid", "OdbcConnection",
  function(dbObj, ...) {
    connection_valid(dbObj@ptr)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDisconnect
#' @export
setMethod("dbDisconnect", "OdbcConnection",
  function(conn, ...) {
    if (!dbIsValid(conn)) {
      warning("Connection already closed.", call. = FALSE)
    }

    on_connection_closed(conn)
    connection_release(conn@ptr)
    invisible(TRUE)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendQuery
#' @param params Optional query parameters, passed on to [dbBind()]
#' @param immediate If `TRUE`, SQLExecDirect will be used instead of
#'   SQLPrepare, and the `params` argument is ignored
#' @export
setMethod("dbSendQuery", c("OdbcConnection", "character"),
  function(conn, statement, params = NULL, ..., immediate = FALSE) {
    if (has_result(conn@ptr)) {
      cli::cli_warn("Cancelling previous query")
    }
    OdbcResult(
      connection = conn,
      statement = statement,
      params = params,
      immediate = immediate
    )
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExecute
#' @export
setMethod("dbExecute", c("OdbcConnection", "character"),
  function(conn, statement, params = NULL, ..., immediate = is.null(params)) {
    rs <- dbSendStatement(conn, statement, params = params, ..., immediate = immediate)
    on.exit(dbClearResult(rs))

    dbGetRowsAffected(rs)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendStatement
#' @param params Query parameters to pass to [dbBind()].
#'   See [dbBind()] for details.
#' @export
setMethod("dbSendStatement", c("OdbcConnection", "character"),
  function(conn, statement, params = NULL, ..., immediate = FALSE) {
    if (has_result(conn@ptr)) {
      cli::cli_warn("Cancelling previous query")
    }
    OdbcResult(
      connection = conn,
      statement = statement,
      params = params,
      immediate = immediate
    )
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod("dbDataType", "OdbcConnection",
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod("dbDataType", c("OdbcConnection", "data.frame"),
  function(dbObj, obj, ...) {
    odbc_data_type_df(dbObj, obj)
  }
)

#' @rawNamespace exportMethods(dbQuoteString)
NULL

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod("dbQuoteIdentifier", c("OdbcConnection", "character"),
  function(conn, x, ...) {
    if (length(x) == 0L) {
      return(DBI::SQL(character()))
    }
    if (any(is.na(x))) {
      cli::cli_abort("{.arg x} can't be {.code NA}.")
    }
    if (nzchar(conn@quote)) {
      x <- gsub(conn@quote, paste0(conn@quote, conn@quote), x, fixed = TRUE)
    }
    nms <- names(x)
    res <- DBI::SQL(paste(conn@quote, x, conn@quote, sep = ""))
    names(res) <- nms
    res
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod("dbQuoteIdentifier", c("OdbcConnection", "SQL"),
  getMethod("dbQuoteIdentifier", c("DBIConnection", "SQL"), asNamespace("DBI"))
)

#' List remote tables and fields for an ODBC connection
#'
#' `dbListTables()` provides names of remote tables accessible through this
#' connection; `dbListFields()` provides names of columns within a table.
#'
#' @inheritParams DBI::dbListTables
#' @param catalog_name,schema_name,table_name Catalog, schema, and table names.
#'
#'   By default, `catalog_name`, `schema_name` and `table_name` will
#'   automatically escape underscores to ensure that you match exactly one
#'   table. If you want to search for multiple tables using wild cards, you
#'   will need to use `odbcConnectionTables()` directly instead.
#'
#' @param table_type The type of the table to return, the default returns
#'   all table types.
#' @returns A character vector of table or field names respectively.
#' @export
setMethod("dbListTables", "OdbcConnection",
  function(conn,
           catalog_name = NULL,
           schema_name = NULL,
           table_name = NULL,
           table_type = NULL,
           ...) {
    check_string(catalog_name, allow_null = TRUE)
    check_string(schema_name, allow_null = TRUE)
    check_string(table_name, allow_null = TRUE)
    check_string(table_type, allow_null = TRUE)

    tables <- odbcConnectionTables(
      conn,
      name = table_name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      table_type = table_type,
      exact = TRUE
    )
    tables[["table_name"]]
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod("dbGetInfo", "OdbcConnection",
  function(dbObj, ...) {
    connection_info(dbObj@ptr)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetQuery
#' @inheritParams DBI::dbFetch
#' @export
setMethod("dbGetQuery", c("OdbcConnection", "character"),
  function(conn,
           statement,
           n = -1,
           params = NULL,
           immediate = is.null(params),
           ...) {
    rs <- dbSendQuery(
      conn,
      statement,
      params = params,
      immediate = immediate,
      ...
    )
    on.exit(dbClearResult(rs))

    df <- dbFetch(rs, n = n, ...)

    if (!dbHasCompleted(rs)) {
      warning("Pending rows", call. = FALSE)
    }

    df
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbBegin
#' @export
setMethod("dbBegin", "OdbcConnection",
  function(conn, ...) {
    connection_begin(conn@ptr)
    invisible(TRUE)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbCommit
#' @export
setMethod("dbCommit", "OdbcConnection",
  function(conn, ...) {
    connection_commit(conn@ptr)
    invisible(TRUE)
  }
)

#' @rdname OdbcConnection
#' @inheritParams DBI::dbRollback
#' @export
setMethod("dbRollback", "OdbcConnection",
  function(conn, ...) {
    connection_rollback(conn@ptr)
    invisible(TRUE)
  }
)
