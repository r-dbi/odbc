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
    interruptibleExecution = TRUE,
    .connection_string = NULL,
    call = caller_env(2)
) {
  check_attributes(attributes, call = call)

  args <- compact(list(...))
  check_args(args)
  connection_string <- build_connection_string(args, .connection_string)

  bigint <- bigint_mappings()[match.arg(bigint, names(bigint_mappings()))]

  if (is.infinite(timeout)) {
    timeout <- 0
  }

  withCallingHandlers(
    ptr <- odbc_connect(
      connection_string,
      timezone = timezone,
      timezone_out = timezone_out,
      encoding = encoding,
      bigint = bigint,
      timeout = timeout,
      r_attributes = attributes,
      interruptible_execution = interruptibleExecution
    ),
    error = function(cnd) {
      check_quoting(args)
    }
  )
  quote <- connection_quote(ptr)

  info <- connection_info(ptr)
  if (!is.null(dbms.name)) {
    info$dbms.name <- dbms.name
  }
  if (!nzchar(info$dbms.name)) {
    cli::cli_abort(
      c(
        "!" = "The ODBC driver failed to generate a DBMS name.",
        "i" = "Please provide one manually with {.arg dbms.name}."
      ),
      call = call
    )
  }

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

build_connection_string <- function(args = list(), string = NULL) {

  args_string <- paste(names(args), args, sep = "=", collapse = ";")

  if (!is.null(string) && !grepl(";$", string) && length(args) > 0) {
    string <- paste0(string, ";")
  }

  paste0(string, args_string)
}

#' Quote special character when connecting
#'
#' @description
#' When connecting to a database using odbc, all the arguments are concatenated
#' into a single connection string that looks like `name1=value1;name2=value2`.
#' That means if your value contains `=` or `;` then it needs to be quoted.
#' Other rules mean that you need to quote any values that starts or ends with
#' white space, or contains `{` or `}`.
#'
#' This function quotes a string in a way that should work for most drivers,
#' but unfortunately there doesn't seem to be an approach that works everywhere.
#' If this function doesn't work for you, you'll need to carefully read the
#' docs for your driver.
#'
#' @export
#' @param x A string to quote.
#' @return A quoted string, wrapped in `I()`.
#' @examples
#' quote_value("abc")
#' quote_value("ab'c")
#'
#' # Real usage is more likely to look like:
#' \dontrun{
#' library(DBI)
#'
#' con <- dbConnect(
#'   odbc::odbc(),
#'   dsn = "reallycooldatabase"
#'   password = odbc::quote_value(Sys.getenv("MY_PASSWORD"))
#' )
#' }
quote_value <- function(x) {
  has_single <- grepl("'", x, fixed = TRUE)
  has_double <- grepl('"', x, fixed = TRUE)

  if (has_single && has_double) {
    abort("Don't know how to escape a value with both single and double quotes.")
  } else if (has_double) {
    quote <- "'"
  } else {
    quote <- '"'
  }

  I(paste0(quote, x, quote))
}

check_args <- function(args) {
  if (length(args) == 0) {
    return()
  }

  if (!all(has_names(args))) {
    abort("All elements of ... must be named.", call = quote(DBI::dbConnect()))
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

check_quoting <- function(args) {
  needs_quoting <- vapply(args, needs_quoting, FUN.VALUE = logical(1))
  if (any(needs_quoting)) {
    # TODO: use cli pluralisation
    args <- paste0("`", names(args)[needs_quoting], "`", collapse = ", ")

    inform(c(
      paste0(args, " contains a special character that may need quoting."),
      i = "Wrap the value in `odbc::quote_value()` to use a heuristic that should work for most drivers.",
      i = "If that still doesn't work, consult your driver's documentation.",
      i = "Otherwise, you can suppress this message by wrapping the value in `I()`."
    ))
  }
}

needs_quoting <- function(x) {
  if (inherits(x, "AsIs")) {
    return(FALSE)
  }

  if (grepl("^\\{.*\\}$", x) || grepl("^(['\\\"]).*\\1$", x)) {
    return(FALSE)
  }

  grepl("[{}=;]| $|^ ", x)
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
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function has been deprecated in favor of [dbListFields()].
#'
#' For a given table this function returns detailed information on
#' all fields / columns.  The expectation is that this is a relatively thin
#' wrapper around the ODBC `SQLColumns` function call, with some of the field
#' names renamed / re-ordered according to the return specifications below.
#'
#' @details
#' In [dbWriteTable()] we make a call to this method
#' to get details on the fields of the table we are writing to.  In particular
#' the columns `data_type`, `column_size`, and `decimal_digits` are used.  An
#' implementation is not necessary for [dbWriteTable()] to work.
#'
#' `odbcConnectionColumns` is routed through the `SQLColumns` ODBC
#' method.  This function, together with remaining catalog functions
#' (`SQLTables`, etc), by default ( `SQL_ATTR_METADATA_ID == false` ) expect
#' either ordinary arguments (OA) in the case of the catalog, or pattern value
#' arguments (PV) in the case of schema/table name.  For these, quoted
#' identifiers do not make sense, so we unquote identifiers prior to the call.
#'
#' @param conn OdbcConnection
#' @param name Table identifiers.
#'   By default, are interpreted as a ODBC search pattern where `_` and `%` are
#'   wild cards. Set `exact = TRUE` to match `_` exactly.
#' @param ... additional parameters to methods
#' @param exact Set to `TRUE` to escape `_` in identifier names so that it
#'   matches exactly, rather than matching any single character. `%` always
#'   matches any number of characters as this is unlikely to appear in a
#'   table name.
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
#' @keywords internal
#' @export
odbcConnectionColumns <- function(conn, name, ..., exact = FALSE) {
  lifecycle::deprecate_warn(
    "1.4.2",
    "odbcConnectionColumns()",
    "dbListFields()"
  )

  odbcConnectionColumns_(conn = conn, name = name, ..., exact = exact)
}

setGeneric(
  "odbcConnectionColumns_",
  valueClass = "data.frame",
  function(conn, name, ..., exact = FALSE) {
    standardGeneric("odbcConnectionColumns_")
  }
)

setMethod("odbcConnectionColumns_", c("OdbcConnection", "Id"),
  function(conn, name, ..., column_name = NULL, exact = FALSE) {
    odbcConnectionColumns_(conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema"),
      column_name = column_name,
      exact = exact
    )
  }
)

setMethod("odbcConnectionColumns_", c("OdbcConnection", "character"),
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

setMethod("odbcConnectionColumns_", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    odbcConnectionColumns_(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

# This function returns a listing of tables accessible
# to the connected user.
# The expectation is that this is a relatively thin
# wrapper around the ODBC `SQLTables` function call,
# albeit returning a subset of the fields.
#
# It is important to note that, similar to the ODBC/API
# call, this method also accomodates pattern-value arguments
# for the catalog, schema, and table name arguments.
#
# If extending this method, be aware that `package:odbc`
# internally uses this method to satisfy both
# DBI::dbListTables and DBI::dbExistsTable methods.
# ( The former also advertises pattern value arguments )
setGeneric(
  "odbcConnectionTables",
  valueClass = "data.frame",
  function(conn, name, ...) {
    standardGeneric("odbcConnectionTables")
  }
)

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

setGeneric(
  "odbcConnectionCatalogs",
  valueClass = "character",
  function(conn) {
    standardGeneric("odbcConnectionCatalogs")
  }
)

setMethod("odbcConnectionCatalogs", "OdbcConnection",
  function(conn) {
    connection_sql_catalogs(conn@ptr)
  }
)

# Currently, for a generic connection the
# catalog_name argument is ignored.
setGeneric(
  "odbcConnectionSchemas",
  valueClass = "character",
  function(conn, catalog_name = NULL) {
    standardGeneric("odbcConnectionSchemas")
  }
)

setMethod("odbcConnectionSchemas", "OdbcConnection",
  function(conn, catalog_name = NULL) {
    connection_sql_schemas(conn@ptr)
  }
)

setGeneric(
  "odbcConnectionTableTypes",
  valueClass = "character",
  function(conn) {
    standardGeneric("odbcConnectionTableTypes")
  }
)

setMethod("odbcConnectionTableTypes", "OdbcConnection",
  function(conn) {
    connection_sql_table_types(conn@ptr)
  }
)


# Internal method, used to check for target existence
# in dbWriteTable.  Historically we used DBI::dbExistsTable
# however its mission may be interpreted more broadly
# ( does this table exists period ) versus the question
# we are trying to answer in dbWriteTable ( does this
# table identifier I may be writing to exist? )  In
# particular, the former may mean, across catalogs or schema;
# the latter we understand to mean:
# 1. At the specified catalog/schema; if not specified then
# 2A. In the current catalog/schema; OR
# 2B. In a temporary table.
#
# While by default we continue to route requests to dbExistsTable,
# this narrower interpretation may allow some back-ends
# to optimize this search.
setGeneric(
  "dbExistsTableForWrite",
  valueClass = "logical",
  function(conn, name, ...) {
    standardGeneric("dbExistsTableForWrite")
  }
)

setMethod("dbExistsTableForWrite", c("OdbcConnection", "Id"),
  function(conn, name, ...) {
    dbExistsTableForWrite(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  }
)

setMethod("dbExistsTableForWrite", c("OdbcConnection", "SQL"),
  function(conn, name, ...) {
    dbExistsTableForWrite(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

setMethod("dbExistsTableForWrite", c("OdbcConnection", "character"),
  function(conn, name, ...) {
    dbExistsTable(conn = conn, name = name, ...)
  }
)
