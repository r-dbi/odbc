#' @include dbi-connection.R
NULL



class_cache <- new.env(parent = emptyenv())

OdbcConnection <- function(
    ...,
    timezone = "UTC",
    timezone_out = "UTC",
    encoding = "",
    bigint = c("integer64", "integer", "numeric", "character"),
    timeout = Inf,
    dbms.name = NULL,
    attributes = NULL,
    .connection_string = NULL
) {

  stopifnot(all(has_names(attributes)))
  stopifnot(all(names(attributes) %in% SUPPORTED_CONNECTION_ATTRIBUTES))

  connection_string <- build_connection_string(..., .string = .connection_string)

  bigint <- bigint_mappings()[match.arg(bigint, names(bigint_mappings()))]

  if (is.infinite(timeout)) {
    timeout <- 0
  }

  ptr <- odbc_connect(
    connection_string,
    timezone = timezone,
    timezone_out = timezone_out,
    encoding = encoding,
    bigint = bigint,
    timeout = timeout,
    r_attributes_ = attributes
  )
  quote <- connection_quote(ptr)

  info <- connection_info(ptr)
  if (!is.null(dbms.name)) {
    info$dbms.name <- dbms.name
  }
  if (!nzchar(info$dbms.name)) {
    stop("The ODBC driver returned an invalid `dbms.name`. Please provide one manually with the `dbms.name` parameter.", call. = FALSE)
  }

  class(info) <- c(info$dbms.name, "driver_info", "list")


  class <- getClassDef(info$dbms.name, inherits = FALSE)
  if (is.null(class)) {
    class <- getClassDef(info$dbms.name, where = class_cache, inherits = FALSE)
    if (is.null(class) || methods::isVirtualClass(class)) {
      setClass(info$dbms.name, contains = "OdbcConnection", where = class_cache)
    }
  }
  new(
    info$dbms.name,
    ptr = ptr,
    quote = quote,
    info = info,
    encoding = encoding
  )
}

build_connection_string <- function(.string = NULL, ...) {
  args <- compact(list(...))
  # check_args(args)

  needs_escape <- grepl("[{}(),;?*=!@]", args) &
    !grepl("^\\{.*\\}$", args) &
    !vapply(args, inherits, "AsIs", FUN.VALUE = logical(1))

  args[needs_escape] <- paste0("{", args[needs_escape], "}")
  args_string <- paste(names(args), args, sep = "=", collapse = ";")

  if (!is.null(.string) && !grepl(";$", .string) && length(args) > 0) {
    .string <- paste0(.string, ";")
  }

  paste0(.string, args_string)
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

# -------------------------------------------------------------------------

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
#' )
#' }
SUPPORTED_CONNECTION_ATTRIBUTES <- c("azure_token")

#' Odbc Connection Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcConnection objects.
#' @name OdbcConnection
NULL

#' odbcConnectionColumns
#'
#' For a given table this function returns detailed information on
#' all fields / columns.  The expectation is that this is a relatively thin
#' wrapper around the ODBC `SQLColumns` function call, with some of the field
#' names renamed / re-ordered according to the return specifications below.
#'
#' In [dbWriteTable()] we make a call to this method
#' to get details on the fields of the table we are writing to.  In particular
#' the columns `data_type`, `column_size`, and `decimal_digits` are used.  An
#' implementation is not necessary for [dbWriteTable()] to work.
#' @inheritParams odbcConnectionTables
#'
#' @seealso The ODBC documentation on
#' [SQLColumns](https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
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
#' - remarks
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
#' @param column_name The name of the column to return, the default returns
#'   all columns.
#' @export
setMethod("odbcConnectionColumns", c("OdbcConnection", "Id"),
  function(conn, name, ..., column_name = NULL, exact = FALSE) {
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
setMethod("odbcConnectionColumns", c("OdbcConnection", "character"),
  function(conn,
           name,
           ...,
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
#' @seealso The ODBC documentation on
#' [Arguments to catalog functions](https://learn.microsoft.com/en-us/sql/odbc/reference/develop-app/arguments-in-catalog-functions).
#' @rdname odbcConnectionColumns
#' @export
setMethod("odbcConnectionColumns", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    odbcConnectionColumns(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

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
#' @seealso The ODBC documentation on
#' [SQLTables](https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function)
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
setMethod("odbcConnectionTables", c("OdbcConnection", "Id"),
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
setMethod("odbcConnectionTables", c("OdbcConnection", "character"),
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
setMethod("odbcConnectionTables", "OdbcConnection",
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
setMethod("odbcConnectionTables", c("OdbcConnection", "SQL"),
  function(conn, name, table_type = NULL, exact = FALSE) {
    odbcConnectionTables(
      conn,
      dbUnquoteIdentifier(conn, name)[[1]],
      table_type = table_type,
      exact = exact
    )
  }
)

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
setMethod("odbcConnectionCatalogs", "OdbcConnection",
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
setMethod("odbcConnectionSchemas", "OdbcConnection",
  function(conn, catalog_name = NULL) {
    connection_sql_schemas(conn@ptr)
  }
)

#' @rdname odbcConnectionSchemas
setMethod("odbcConnectionSchemas", c("OdbcConnection", "character"),
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
setMethod("odbcConnectionTableTypes", "OdbcConnection",
  function(conn) {
    connection_sql_table_types(conn@ptr)
  }
)
