#' @include Driver.R
NULL

#' Odbc Connection Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcConnection objects.
#' @name OdbcConnection
NULL

class_cache <- new.env(parent = emptyenv())

OdbcConnection <- function(
  dsn = NULL,
  ...,
  timezone = "UTC",
  encoding = "",
  bigint = c("integer64", "integer", "numeric", "character"),
  timeout = Inf,
  driver = NULL,
  server = NULL,
  database = NULL,
  uid = NULL,
  pwd = NULL,
  dbms.name = NULL,
  .connection_string = NULL) {

  args <- c(dsn = dsn, driver = driver, server = server, database = database, uid = uid, pwd = pwd, list(...))
  stopifnot(all(has_names(args)))

  connection_string <- paste0(.connection_string, paste(collapse = ";", sep = "=", names(args), args))

  bigint <- bigint_mappings()[match.arg(bigint, names(bigint_mappings()))]

  if (is.infinite(timeout)) {
    timeout <- 0
  }

  ptr <- odbc_connect(connection_string, timezone = timezone, encoding = encoding, bigint = bigint, timeout = timeout)
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

#' @title odbcConnectionColumns
#' @name odbcConnectionColumns
#'
#' @description For a given table this function recturns detailed information on
#' all fields / columns.  The expectation is that this is a relatively thin
#' wrapper around the ODBC SQLColumns function call.
#'
#' @details For more information see SQLColumns ODBC function
#' @param conn OdbcConnection
#' @param name table we wish to get information on
#' @param ... additional parameters to methods
#'
#' @seealso The ODBC documentation on [SQLColumns](https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
#' for further details on the expected output.
#'
#' @return data.frame with columns
#' \itemize{
#'   \item{table_cat}
#'   \item{table_schem}
#'   \item{table_name}
#'   \item{column_name}
#'   \item{data_type}
#'   \item{type_name}
#'   \item{column_size}
#'   \item{buffer_length}
#'   \item{decimal_digits}
#'   \item{numeric_precision_radix}
#'   \item{nullable}
#"   \item{remarks}
#'   \item{column_def}
#'   \item{sql_data_type}
#'   \item{sql_datetime_subtype}
#'   \item{char_octet_length}
#'   \item{ordinal_position}
#' }
#' @export
setGeneric(
  "odbcConnectionColumns",
  valueClass = "data.frame",
  function(conn, name, ...) {
    standardGeneric("odbcConnectionColumns")
  }
)

#' @name odbcConnectionColumns
#' @aliases odbcConnectionColumns,OdbcConnection,Id-method
#' @inheritParams odbcConnectionColumns
#' @param column_name The name of the column to return, the default returns all columns.
#'
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "Id"),
  function(conn, name, column_name = NULL) {

    odbcConnectionColumns(conn,
      name = name@name[["table"]],
      catalog_name = name@name[["catalog"]],
      schema_name = name@name[["schema"]],
      column_name = column_name)
  }
)

#' @name odbcConnectionColumns
#' @aliases odbcConnectionColumns,OdbcConnection,character-method
#' @inheritParams odbcConnectionColumns
#' @param catalog_name charaacter catalog where the table is located
#' @param schema_name charaacter schema where the table is located
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, column_name = NULL) {
    detail <-
      connection_sql_columns(conn@ptr,
        table_name = name,
        catalog_name = catalog_name,
        schema_name = schema_name,
        column_name = column_name)
    # Re-order/rename columns to make output ODBC-like
    detail <- detail[, c("catalog_name", "schema_name", "table_name", "name",
      "data_type", "field.type", "column_size", "buffer_length",
      "decimal_digits", "numeric_precision_radix", "nullable", "remarks",
      "column_default", "sql_data_type", "sql_datetime_subtype",
      "char_octet_length", "ordinal_position")]
    names(detail)[c(1, 2, 4, 6, 13)] <- c("table_cat", "table_schem",
      "column_name", "type_name", "column_def")

    detail
  }
)

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
    odbcDataType(dbObj, obj)
  })

#' @rdname OdbcConnection
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbcConnection", "data.frame"),
  function(dbObj, obj, ...) {
    vapply(obj, odbcDataType, con = dbObj, FUN.VALUE = character(1), USE.NAMES = TRUE)
  })

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
    DBI::SQL(paste(conn@quote, encodeString(x), conn@quote, sep = ""))
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
      column_name = column_name)[["column_name"]]
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
  function(conn, statement, n = -1, ...) {
    rs <- dbSendQuery(conn, statement, ...)
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
#' @return A data frame with three columns.
#' If a given driver does not have any attributes the last two columns will be
#' `NA`.
#' \describe{
#'   \item{name}{Name of the driver}
#'   \item{attribute}{Driver attribute name}
#'   \item{value}{Driver attribute value}
#' }
#' @export
odbcListDrivers <- function() {
  res <- list_drivers_()
  if (nrow(res) > 0) {
    res[res == ""] <- NA_character_
  }
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
