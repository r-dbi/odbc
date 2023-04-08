#' @include Driver.R
NULL

#' Supported Connection Attributes
#'
#' These (pre) connection attributes are supported and can be passed as
#' part of the `dbConnect` call in the named list `attributes` parameter:
#'
#' * `azure_token`: This should be a string scalar; in particular Azure Active
#'   Directory authentication token.  Only for use with Microsoft SQL Server and
#'   with limited support away from the OEM Microsoft driver.
#' @rdname ConnectionAttributes
#' @aliases ConnectionAttributes
#' @usage NULL
#' @format NULL
#' @examples
#' \dontrun{
#' conn <- dbConnect(
#'   odbc::odbc(),
#'   dsn = "my_azure_mssql_db",
#'   Encrypt = "yes",
#'   attributes = list("azure_token" = .token)
#' }
SUPPORTED_CONNECTION_ATTRIBUTES <-
  c("azure_token")

#' Odbc Connection Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcConnection objects.
#' @name OdbcConnection
NULL

class_cache <- new.env()

OdbcConnection <- function(
  dsn = NULL,
  ...,
  timezone = "UTC",
  timezone_out = "UTC",
  encoding = "",
  bigint = c("integer64", "integer", "numeric", "character"),
  timeout = Inf,
  driver = NULL,
  server = NULL,
  database = NULL,
  uid = NULL,
  pwd = NULL,
  dbms.name = NULL,
  attributes = NULL,
  .connection_string = NULL) {

  args <- c(dsn = dsn, driver = driver, server = server, database = database, uid = uid, pwd = pwd, list(...))
  stopifnot(all(has_names(args)))
  stopifnot(all(has_names(attributes)))
  stopifnot(all(names(attributes) %in% SUPPORTED_CONNECTION_ATTRIBUTES))

  connection_string <- paste0(.connection_string, paste(collapse = ";", sep = "=", names(args), args))

  bigint <- bigint_mappings()[match.arg(bigint, names(bigint_mappings()))]

  if (is.infinite(timeout)) {
    timeout <- 0
  }

  ptr <- odbc_connect(connection_string, timezone = timezone, timezone_out = timezone_out, encoding = encoding, bigint = bigint, timeout = timeout, r_attributes_ = attributes)
  quote <- connection_quote(ptr)

  info <- connection_info(ptr)
  if (!is.null(dbms.name)) {
    info$dbms.name <- dbms.name
  }
  if (!nzchar(info$dbms.name)) {
    stop("The ODBC driver returned an invalid `dbms.name`. Please provide one manually with the `dbms.name` parameter.", call. = FALSE)
  }

  class(info) <- c(info$dbms.name, "driver_info", "list")

  class <- getClassDef(info$dbms.name, where = class_cache, inherits = FALSE)
  if (is.null(class) || methods::isVirtualClass(class)) {
    setClass(info$dbms.name,
      contains = "OdbcConnection", where = class_cache)
  }
  res <- new(info$dbms.name, ptr = ptr, quote = quote, info = info, encoding = encoding)
}

#' @rdname OdbcConnection
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

#' odbcConnectionColumns
#'
#' For a given table this function returns detailed information on
#' all fields / columns.  The expectation is that this is a relatively thin
#' wrapper around the ODBC `SQLColumns` function call, with some of the field names
#' renamed / re-ordered according to the return specifications below.
#'
#' In [dbWriteTable()] we make a call to this method
#' to get details on the fields of the table we are writing to.  In particular
#' the columns `data_type`, `column_size`, and `decimal_digits` are used.  An
#' implementation is not necessary for [dbWriteTable()] to work.
#' @param conn OdbcConnection
#' @param name table we wish to get information on
#' @param ... additional parameters to methods
#'
#' @seealso The ODBC documentation on [SQLColumns](https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
#' for further details.
#'
#' @return data.frame with columns
#' - name
#' - field.type - equivalent to type_name in SQLColumns output
#' - table_name
#' - schema_name
#' - catalog_name
#' - data_type
#' - column_size
#' - buffer_length
#' - decimal_digits
#' - numeric_precision_radix
#" - remarks
#' - column_default
#' - sql_data_type
#' - sql_datetime_subtype
#' - char_octet_length
#' - ordinal_position
#' - nullable
#' @export
setGeneric(
  "odbcConnectionColumns",
  valueClass = "data.frame",
  function(conn, name, ...) {
    standardGeneric("odbcConnectionColumns")
  }
)

#' @rdname odbcConnectionColumns
#' @param column_name The name of the column to return, the default returns all columns.
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "Id"),
  function(conn, name, column_name = NULL) {

    connection_sql_columns(conn@ptr,
      table_name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      column_name = column_name)
  }
)

#' @rdname odbcConnectionColumns
#' @param catalog_name character catalog where the table is located
#' @param schema_name character schema where the table is located
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, column_name = NULL) {

    connection_sql_columns(conn@ptr,
      table_name = name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name)

  }
)

#' @details `odbcConnectionColumns` is routed through the `SQLColumns` ODBC
#'  method.  This function, together with remaining catalog functions
#'  (`SQLTables`, etc), by default ( `SQL_ATTR_METADATA_ID == false` ) expect
#'  either ordinary arguments (OA) in the case of the catalog, or pattern value
#'  arguments (PV) in the case of schema/table name.  For these, quoted
#'  identifiers do not make sense, so we unquote identifiers prior to the call.
#' @seealso The ODBC documentation on [Arguments to catalog functions](https://learn.microsoft.com/en-us/sql/odbc/reference/develop-app/arguments-in-catalog-functions?view=sql-server-ver16).
#' @rdname odbcConnectionColumns
#' @export
setMethod(
  "odbcConnectionColumns", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    odbcConnectionColumns(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  })

# TODO: show encoding, timezone, bigint mapping
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

    on_connection_closed(conn)
    connection_release(conn@ptr)
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendQuery
#' @param params Optional query parameters, passed on to [dbBind()]
#' @param immediate If `TRUE`, SQLExecDirect will be used instead of
#'   SQLPrepare, and the `params` argument is ignored
#' @export
setMethod(
  "dbSendQuery", c("OdbcConnection", "character"),
  function(conn, statement, params = NULL, ..., immediate = FALSE) {
    res <- OdbcResult(connection = conn, statement = statement, params = params, immediate = immediate)
    res
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbSendStatement
#' @param params Query parameters to pass to [dbBind()], See [dbBind()] for details.
#' @export
setMethod(
  "dbSendStatement", c("OdbcConnection", "character"),
  function(conn, statement, params = NULL, ..., immediate = FALSE) {
    res <- OdbcResult(connection = conn, statement = statement, params = params, immediate = immediate)
    res
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbcConnection",
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod("dbDataType", c("OdbcConnection", "data.frame"), odbc_data_type_df)

#' @rawNamespace exportMethods(dbQuoteString)
NULL

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod(
  "dbQuoteIdentifier", c("OdbcConnection", "character"),
  function(conn, x, ...) {
    if (length(x) == 0L) {
      return(DBI::SQL(character()))
    }
    if (any(is.na(x))) {
      stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
    }
    if (nzchar(conn@quote)) {
      x <- gsub(conn@quote, paste0(conn@quote, conn@quote), x, fixed = TRUE)
    }
    nms <- names(x)
    res <- DBI::SQL(paste(conn@quote, encodeString(x), conn@quote, sep = ""))
    names(res) <- nms
    res
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbQuoteIdentifier
#' @export
setMethod(
  "dbQuoteIdentifier", c("OdbcConnection", "SQL"),
  getMethod("dbQuoteIdentifier", c("DBIConnection", "SQL"), asNamespace("DBI")))

#' @inherit DBI::dbListTables
#' @param catalog_name The name of the catalog to return, the default returns all catalogs.
#' @param schema_name The name of the schema to return, the default returns all schemas.
#' @param table_name The name of the table to return, the default returns all tables.
#' @param table_type The type of the table to return, the default returns all table types.
#' @aliases dbListTables
#' @details
#' \code{\%} can be used as a wildcard in any of the search parameters to
#'   match 0 or more characters. `_` can be used to match any single character.
#' @seealso The ODBC documentation on [Pattern Value Arguments](https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/pattern-value-arguments)
#'   for further details on the supported syntax.
#' @export
setMethod(
  "dbListTables", "OdbcConnection",
  function(conn, catalog_name = NULL, schema_name = NULL, table_name = NULL,
    table_type = NULL, ...) {

    connection_sql_tables(conn@ptr,
      catalog_name = catalog_name,
      schema_name = schema_name,
      table_name = table_name,
      table_type = table_type)$table_name
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbExistsTable
#' @export
setMethod(
  "dbExistsTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    stopifnot(length(name) == 1)
    df <- connection_sql_tables(conn@ptr, table_name = name)
    NROW(df) > 0
  })

#' @inherit DBI::dbListFields
#' @inheritParams DBI::dbListFields
#' @aliases dbListFields
#' @inheritParams dbListTables,OdbcConnection-method
#' @param column_name The name of the column to return, the default returns all columns.
#' @inherit dbListTables,OdbcConnection-method details
#' @export
setMethod(
  "dbListFields", c("OdbcConnection", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, column_name = NULL, ...) {
    odbcConnectionColumns(conn,
      name = name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name)[["name"]]
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbRemoveTable
#' @export
setMethod(
  "dbRemoveTable", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbExecute(conn, paste("DROP TABLE ", name))
    on_connection_updated(conn, name)
    invisible(TRUE)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbcConnection",
  function(dbObj, ...) {
    info <- connection_info(dbObj@ptr)
    structure(info, class = c(info$dbms.name, "driver_info", "list"))
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbGetQuery
#' @inheritParams DBI::dbFetch
#' @export
setMethod("dbGetQuery", signature("OdbcConnection", "character"),
  function(conn, statement, n = -1, params = NULL, ...) {
    rs <- dbSendQuery(conn, statement, params = params, ...)
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

#' List Available ODBC Drivers
#'
#' List the available drivers on your system. See the
#' [Installation](https://github.com/r-dbi/odbc#installation) section of the
#' package README for details on how to install drivers for the most common
#' databases.
#'
#' @param keep A character vector of driver names to keep in the results, if
#'   `NULL` (the default) will keep all drivers.
#' @param filter A character vector of driver names to filter from the results, if
#'   `NULL` (the default) will not filter any drivers.
#' @return A data frame with three columns.
#' If a given driver does not have any attributes the last two columns will be
#' `NA`. Drivers can be excluded from being returned by setting the
#' \code{odbc.drivers.filter} option.
#' \describe{
#'   \item{name}{Name of the driver}
#'   \item{attribute}{Driver attribute name}
#'   \item{value}{Driver attribute value}
#' }
#' @export
odbcListDrivers <- function(keep = getOption("odbc.drivers_keep"), filter = getOption("odbc.drivers_filter")) {
  res <- list_drivers_()

  if (nrow(res) > 0) {
    res[res == ""] <- NA_character_

    if (!is.null(keep)) {
      res <- res[res[["name"]] %in% keep, ]
    }

    if (!is.null(filter)) {
      res <- res[!res[["name"]] %in% filter, ]
    }
  }

  res
}

#' List Available Data Source Names
#'
#' List the available data sources on your system. See the [DSN Configuration
#' files](https://github.com/r-dbi/odbc#dsn-configuration-files) section of the
#' package README for details on how to install data sources for the most
#' common databases.
#'
#' @return A data frame with two columns.
#' \describe{
#'   \item{name}{Name of the data source}
#'   \item{description}{Data Source description}
#' }
#' @export
odbcListDataSources <- function() {
  list_data_sources_()
}

#' Set the Transaction Isolation Level for a Connection
#'
#' @param levels One or more of \Sexpr[stage=render, results=rd]{odbc:::choices_rd(names(odbc:::transactionLevels()))}.
#' @inheritParams DBI::dbDisconnect
#' @seealso \url{https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/setting-the-transaction-isolation-level}
#' @export
#' @noMd
#' @examples
#' \dontrun{
#'   # Can use spaces or underscores in between words.
#'   odbcSetTransactionIsolationLevel(con, "read uncommitted")
#'
#'   # Can also use the full constant name.
#'   odbcSetTransactionIsolationLevel(con, "SQL_TXN_READ_UNCOMMITTED")
#' }
odbcSetTransactionIsolationLevel <- function(conn, levels) {
  # Convert to lowercase, spaces to underscores, remove sql_txn prefix
  levels <- tolower(levels)
  levels <- gsub(" ", "_", levels)
  levels <- sub("sql_txn_", "", levels)
  levels <- match.arg(tolower(levels), names(transactionLevels()), several.ok = TRUE)

  set_transaction_isolation(conn@ptr, transactionLevels()[levels])
}
