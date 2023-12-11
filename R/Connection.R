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
#' @keywords internal
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

class_cache <- new.env(parent = emptyenv())

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

  args <- c(
    dsn = dsn,
    driver = driver,
    server = server,
    database = database,
    uid = uid,
    pwd = pwd,
    list(...)
  )
  check_args(args)

  stopifnot(all(has_names(attributes)))
  stopifnot(all(names(attributes) %in% SUPPORTED_CONNECTION_ATTRIBUTES))

  connection_string <- paste0(.connection_string, build_connection_string(args))

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

check_args <- function(args) {
  stopifnot(all(has_names(args)))
  if (length(args) == 0) {
    return(args)
  }

  name_groups <- split(names(args), tolower(names(args)))
  bad_names <- name_groups[lengths(name_groups) > 1]
  if (length(bad_names) > 0) {
    bullets <- vapply(bad_names, paste0, collapse = ", ", FUN.VALUE = character(1))

    abort(
      c(
        "After ignoring case, some arguments have the same name:",
        set_names(bullets, "*")
      ),
      call = quote(DBI::dbConnect())
    )
  }
}

build_connection_string <- function(args) {
  needs_escape <- grepl("[{}(),;?*=!@]", args) &
    !grepl("^\\{.*\\}$", args) &
    !vapply(args, inherits, "AsIs", FUN.VALUE = logical(1))

  args[needs_escape] <- paste0("{", args[needs_escape], "}")
  paste(names(args), args, sep = "=", collapse = ";")
}

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
#' @inheritParams odbcConnectionTables
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
#'
#' @rdname odbcConnectionColumns
#' @export
setGeneric(
  "odbcConnectionColumns",
  valueClass = "data.frame",
  function(conn, name, ..., exact = FALSE) {
    standardGeneric("odbcConnectionColumns")
  }
)

#' @rdname odbcConnectionColumns
#' @param column_name The name of the column to return, the default returns all columns.
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "Id"),
  function(conn, name, column_name = NULL, exact = FALSE) {
    odbcConnectionColumns(conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      column_name = column_name,
      exact = exact
    )
  }
)

#' @rdname odbcConnectionColumns
#' @export
setMethod(
  "odbcConnectionColumns",
  c("OdbcConnection", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {

    if (exact) {
      schema_name <- escapePattern(schema_name)
      name <- escapePattern(name)
      column_name <- escapePattern(column_name)
    }
    connection_sql_columns(
      conn@ptr,
      table_name = name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name
    )
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

#' odbcConnectionTables
#'
#' This function returns a listing of tables accessible
#' to the connected user.
#' The expectation is that this is a relatively thin
#' wrapper around the ODBC `SQLTables` function call,
#' albeit returning a subset of the fields.
#'
#' It is important to note that, similar to the ODBC/API
#' call, this method also accomodates pattern-value arguments
#' for the catalog, schema, and table name arguments.
#'
#' If extending this method, be aware that `package:odbc`
#' internally uses this method to satisfy both
#' DBI::dbListTables and DBI::dbExistsTable methods.
#' ( The former also advertises pattern value arguments )
#'
#' @param conn OdbcConnection
#' @param name,catalog_name,schema_name Catalog, schema, and table identifiers.
#'   By default, are interpreted as a ODBC search pattern where `_` and `%` are
#'   wild cards. Set `exact = TRUE` to match `_` exactly.
#' @param ... additional parameters to methods
#' @param exact Set to `TRUE` to escape `_` in identifier names so that it
#'   matches exactly, rather than matching any single character. `%` always
#'   matches any number of characters as this is unlikely to appear in a
#'   table name.
#'
#' @seealso The ODBC documentation on [SQLTables](https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
#' for further details.
#'
#' @return data.frame with columns
#' - table_catalog
#' - table_schema
#' - table_name
#' - table_remarks
#' @rdname odbcConnectionTables
setGeneric(
  "odbcConnectionTables",
  valueClass = "data.frame",
  function(conn, name, ...) {
    standardGeneric("odbcConnectionTables")
  }
)

#' @rdname odbcConnectionTables
#' @param table_type List tables of this type, for example 'VIEW'.
#' See odbcConnectionTableTypes for a listing of available table
#' types for your connection.
setMethod(
  "odbcConnectionTables",
  c("OdbcConnection", "Id"),
  function(conn, name, table_type = NULL, exact = FALSE) {

    odbcConnectionTables(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      table_type = table_type,
      exact = exact
    )
  }
)

#' @rdname odbcConnectionTables
setMethod(
  "odbcConnectionTables",
  c("OdbcConnection", "character"),
  function(conn,
           name,
           catalog_name = NULL,
           schema_name = NULL,
           table_type = NULL,
           exact = FALSE) {
    if (exact) {
      catalog_name <- escapePattern(catalog_name)
      schema_name <- escapePattern(schema_name)
      name <- escapePattern(name)
    }
    connection_sql_tables(
      conn@ptr,
      catalog_name = catalog_name,
      schema_name = schema_name,
      table_name = name,
      table_type = table_type
    )
  }
)

#' @rdname odbcConnectionTables
setMethod(
  "odbcConnectionTables",
  c("OdbcConnection"),
  function(conn,
           name = NULL,
           catalog_name = NULL,
           schema_name = NULL,
           table_type = NULL,
           exact = FALSE) {

    odbcConnectionTables(
      conn,
      name = "%",
      catalog_name = catalog_name,
      schema_name = schema_name,
      table_type = table_type,
      exact = exact
    )
  }
)

#' @rdname odbcConnectionTables
setMethod(
  "odbcConnectionTables", c("OdbcConnection", "SQL"),
  function(conn, name, table_type = NULL, exact = FALSE) {
    odbcConnectionTables(
      conn,
      dbUnquoteIdentifier(conn, name)[[1]],
      table_type = table_type,
      exact = exact
    )
  })

#' odbcConnectionCatalogs
#'
#' This function returns a listing of available
#' catalogs.
#' @param conn OdbcConnection
#' @rdname odbcConnectionCatalogs
setGeneric(
  "odbcConnectionCatalogs",
  valueClass = "character",
  function(conn) {
    standardGeneric("odbcConnectionCatalogs")
  }
)

#' @rdname odbcConnectionCatalogs
setMethod(
  "odbcConnectionCatalogs",
  c("OdbcConnection"),
  function(conn) {
    connection_sql_catalogs(conn@ptr)
  }
)

#' odbcConnectionSchemas
#'
#' This function returns a listing of available
#' schemas.
#'
#' Currently, for a generic connection the
#' catalog_name argument is ignored.
#'
#' @param conn OdbcConnection
#' @param catalog_name Catalog where
#' we are looking to list schemas.
#' @keywords internal
#' @rdname odbcConnectionSchemas
setGeneric(
  "odbcConnectionSchemas",
  valueClass = "character",
  function(conn, catalog_name) {
    standardGeneric("odbcConnectionSchemas")
  }
)

#' @rdname odbcConnectionSchemas
setMethod(
  "odbcConnectionSchemas",
  c("OdbcConnection"),
  function(conn, catalog_name = NULL) {
    connection_sql_schemas(conn@ptr)
  }
)

#' @rdname odbcConnectionSchemas
setMethod(
  "odbcConnectionSchemas",
  c("OdbcConnection", "character"),
  function(conn, catalog_name) {
    connection_sql_schemas(conn@ptr)
  }
)

#' odbcConnectionTableTypes
#'
#' This function returns a listing of table
#' types available in database.
#' @param conn OdbcConnection
#' @rdname odbcConnectionTableTypes
setGeneric(
  "odbcConnectionTableTypes",
  valueClass = "character",
  function(conn) {
    standardGeneric("odbcConnectionTableTypes")
  }
)

#' @rdname odbcConnectionTableTypes
setMethod(
  "odbcConnectionTableTypes",
  "OdbcConnection",
  function(conn) {
    connection_sql_table_types(conn@ptr)
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
#' @param table_type The type of the table to return, the default returns all table types.
#' @returns A character vector of table or field names respectively.
#' @export
setMethod(
  "dbListTables", "OdbcConnection",
  function(conn,
           catalog_name = NULL,
           schema_name = NULL,
           table_name = NULL,
           table_type = NULL,
           ...) {

    tables <- odbcConnectionTables(
      conn,
      name = table_name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      table_type = table_type,
      exact = TRUE
    )
    tables[["table_name"]]
  })

#' @rdname dbListTables-OdbcConnection-method
#' @inheritParams DBI::dbListFields
#' @param column_name The name of the column to return, the default returns all columns.
#' @export
setMethod(
  "dbListFields", c("OdbcConnection", "character"),
  function(
      conn,
      name,
      catalog_name = NULL,
      schema_name = NULL,
      column_name = NULL,
      ...
  ) {
    cols <- odbcConnectionColumns(
      conn,
      name = name,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name,
      exact = TRUE)
    cols[["name"]]
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

#' List Configured ODBC Drivers
#'
#' @description
#'
#' Collect information about the configured driver names. A driver must be both
#' installed and configured with the driver manager to be included in this list.
#' Configuring a driver name just sets up a lookup table (e.g. in
#' `odbcinst.ini`) to allow users to pass only the driver name to [dbConnect()].
#'
#' Driver names that are not configured with the driver manager (and thus
#' do not appear in this function's output) can still be
#' used in [dbConnect()] by providing a path to a driver directly.
#'
#' @param keep,filter A character vector of driver names to keep in or remove
#'   from the results, respectively. If `NULL`, all driver names will be kept,
#'   or none will be removed, respectively. The `odbc.drivers_keep` and
#'   `odbc.drivers_filter` options control the argument defaults.
#'
#'   Driver names are first processed with `keep`, then `filter`. Thus, if a
#'   driver name is in both `keep` and `filter`, it won't appear in output.
#'
#' @return A data frame with three columns.
#'
#' \describe{
#'   \item{name}{Name of the driver. The entries in this column can be
#'     passed to the `driver` argument of [dbConnect()] (as long as the
#'     driver accepts the argument).}
#'   \item{attribute}{Driver attribute name.}
#'   \item{value}{Driver attribute value.}
#' }
#'
#' If a driver has multiple attributes, there will be one row per attribute,
#' each with the same driver `name`. If a given driver name does not have any
#' attributes, the function will return one row with the driver `name`, but
#' the last two columns will be `NA`.
#'
#' @section Configuration:
#'
#' This function interfaces with the driver manager to collect information
#' about the available driver names.
#'
#' For **MacOS and Linux**, the odbc package supports the unixODBC driver
#' manager. unixODBC looks to the `odbcinst.ini` _configuration file_ for
#' information on driver names. Find the location(s) of your `odbcinst.ini`
#' file(s) with `odbcinst -j`.
#'
#' In this example `odbcinst.ini` file:
#'
#' ```
#' [MySQL Driver]
#' Driver=/opt/homebrew/Cellar/mysql/8.2.0_1/lib/libmysqlclient.dylib
#' ```
#'
#' Then the driver name is `MySQL Driver`, which will appear in the `name`
#' column of this function's output. To pass the driver name as the `driver`
#' argument to [dbConnect()], pass it as a string, like `"MySQL Driver"`.
#'
#' **Windows** is [bundled](https://learn.microsoft.com/en-us/sql/odbc/admin/odbc-data-source-administrator)
#' with an ODBC driver manager.
#'
#' In this example, function output would include 1 row: the `name` column
#' would read `"MySQL Driver"`, `attribute` would be `"Driver"`, and `value`
#' would give the file path to the driver. Additional key-value pairs
#' under the driver name would add additional rows with the same `name` entry.
#'
#' When a driver is configured with a driver manager, information on the driver
#' will be automatically passed on to [dbConnect()] when its `driver` argument
#' is set. For an example, see the same section in the [odbcListDataSources()]
#' help-file. Instead of configuring driver information with a driver manager,
#' it is also possible to provide a path to a driver directly to [dbConnect()].
#'
#' @seealso
#' [odbcListDataSources()]
#'
#' @examplesIf FALSE
#' odbcListDrivers()
#'
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

#' List Configured Data Source Names
#'
#' @description
#'
#' Collect information about the available data source names (DSNs). A DSN must
#' be both installed and configured with the driver manager to be included in
#' this list. Configuring a DSN just sets up a lookup table (e.g. in
#' `odbc.ini`) to allow users to pass only the DSN to [dbConnect()].
#'
#' DSNs that are not configured with the driver manager can still be
#' connected to with [dbConnect()] by providing DSN metadata directly.
#'
#' @return A data frame with two columns:
#' \describe{
#'   \item{name}{Name of the data source. The entries in this column can be
#'     passed to the `dsn` argument of [dbConnect()].}
#'   \item{description}{Data source description.}
#' }
#'
#' @section Configuration:
#'
#' This function interfaces with the driver manager to collect information
#' about the available data source names.
#'
#' For **MacOS and Linux**, the odbc package supports the unixODBC driver
#' manager. unixODBC looks to the `odbc.ini` _configuration file_ for information
#' on DSNs. Find the location(s) of your `odbc.ini` file(s) with `odbcinst -j`.
#'
#' In this example `odbc.ini` file:
#'
#' ```
#' [MySQL]
#' Driver = MySQL Driver
#' Database = test
#' Server = 127.0.0.1
#' User = root
#' password = root
#' Port = 3306
#' ```
#'
#' ...the data source name is `MySQL`, which will appear in the `name`
#' column of this function's output. To pass the DSN as the `dsn` argument to
#' [dbConnect()], pass it as a string, like `"MySQL"`.
#' `Driver = MySQL Driver` references the driver `name` in [odbcListDrivers()]
#' output.
#'
#' **Windows** is [bundled](https://learn.microsoft.com/en-us/sql/odbc/admin/odbc-data-source-administrator)
#' with an ODBC driver manager.
#'
#' When a DSN is configured with a driver manager, information on the DSN will
#' be automatically passed on to [dbConnect()] when its `dsn` argument is set.
#'
#' For example, with the `MySQL` data source name configured, and the driver
#' name `MySQL Driver` appearing in [odbcListDrivers()] output, the code:
#'
#' ```
#' con <-
#'   dbConnect(
#'     odbc::odbc(),
#'     Driver = "MySQL Driver",
#'     Database = "test",
#'     Server = "127.0.0.1",
#'     User = "root",
#'     password = "root",
#'     Port = 3306
#'   )
#' ```
#'
#' ...can be written:
#'
#' ```
#' con <- dbConnect(odbc::odbc(), dsn = "MySQL")
#' ```
#'
#' In this case, `dbConnect()` will look up the information defined for `MySQL`
#' in the driver manager (in our example, `odbc.ini`) and automatically
#' pass the needed arguments.
#'
#' @seealso
#'
#' [odbcListDrivers()]
#'
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
