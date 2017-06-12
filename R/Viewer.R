#' Return the object hierarchy supported by a connection.
#'
#' Lists the object types and metadata known by the connection, and how those
#' object types relate to each other.
#'
#' The returned hierarchy takes the form of a nested list, in which each object
#' type supported by the connection is a named list with the following
#' attributes:
#'
#' \describe{
#'   \item{contains}{A list of other object types contained by the object, or
#'       "data" if the object contains data}
#'   \item{icon}{An optional path to an icon representing the type}
#' }
#
#' For instance, a connection in which the top-level object is a schema that
#' contains tables and views, the function will return a list like the
#' following:
#'
#' \preformatted{list(schema = list(contains = list(
#'                    list(name = "table", contains = "data")
#'                    list(name = "view", contains = "data"))))
#'
#' }
#' @param connection A connection object, as returned by `dbConnect()`.
#' @return The hierarchy of object types supported by the connection.
#' @export
# nocov start
odbcListObjectTypes <- function(connection) {
  UseMethod("odbcListObjectTypes")
}

#' @export
odbcListObjectTypes.default <- function(connection) {
  # slurp all the objects in the database so we can determine the correct
  # object hierarchy

  # all databases contain tables, at a minimum
  obj_types <- list(table = list(contains = "data"))

  # see if we have views too
  table_types <- connection_sql_tables(connection@ptr, "", "", "", "%")[["table_type"]]
  if (any(table_types == "VIEW")) {
    obj_types <- c(obj_types, list(view = list(contains = "data")))
  }

  # check for multiple schema or a named schema
  schemas <- connection_sql_tables(connection@ptr, "", "%", "", "")[["table_schema"]]
  if (length(schemas) > 1 || nzchar(schemas)) {
    obj_types <- list(schema = list(contains = obj_types))
  }

  # check for multiple catalogs
  catalogs <- connection_sql_tables(connection@ptr, "%", "", "", "")[["table_catalog"]]
  if (length(catalogs) > 1) {
    obj_types <- list(catalog = list(contains = obj_types))
  }

  obj_types
}

#' List objects in a connection.
#'
#' Lists all of the objects in the connection, or all the objects which have
#' specific attributes.
#'
#' When used without parameters, this function returns all of the objects known
#' by the connection. Any parameters passed will filter the list to only objects
#' which have the given attributes; for instance, passing \code{schema = "foo"}
#' will return only objects matching the schema \code{foo}.
#'
#' @param connection A connection object, as returned by `dbConnect()`.
#' @param ... Attributes to filter by.
#' @return A data frame with \code{name} and \code{type} columns, listing the
#'   objects.
#' @export
odbcListObjects <- function(connection, ...) {
  UseMethod("odbcListObjects")
}

#' @export
odbcListObjects.OdbcConnection <- function(connection, catalog = NULL, schema = NULL, name = NULL, type = NULL, ...) {

  # if no catalog was supplied but this database has catalogs, return a list of
  # catalogs
  if (is.null(catalog)) {
    catalogs <- connection_sql_tables(connection@ptr, catalog_name = catalog %||% "%", "", "", NULL)[["table_catalog"]]
    if (length(catalogs) > 1) {
      return(
        data.frame(
          name = catalogs,
          type = rep("catalog", times = length(catalogs)),
          stringsAsFactors = FALSE
      ))
    }
  }

  # if no schema was supplied but this database has schema, return a list of
  # schema
  if (is.null(schema)) {
    schemas <- connection_sql_tables(connection@ptr, "", schema_name = schema %||% "%", "", NULL)[["table_schema"]]
    if (length(schemas) > 1) {
      return(
        data.frame(
          name = schemas,
          type = rep("schema", times = length(schemas)),
          stringsAsFactors = FALSE
      ))
    }
  }

  objs <- connection_sql_tables(connection@ptr, catalog, schema, name, type)
  # just return a list of the objects and their types, possibly filtered by the
  # options above
  data.frame(
    name = objs[["table_name"]],
    type = tolower(objs[["table_type"]]),
    stringsAsFactors = FALSE
  )
}

#' List columns in an object.
#'
#' Lists the names and types of each column (field) of a specified object.
#'
#' The object to inspect must be specified as one of the arguments
#' (e.g. \code{table = "employees"}); depending on the driver and underlying
#' data store, additional specification arguments may be required.
#'
#' @param connection A connection object, as returned by `dbConnect()`.
#' @param ... Parameters specifying the object.
#' @return A data frame with \code{name} and \code{type} columns, listing the
#'   object's fields.
#' @export
odbcListColumns <- function(connection, ...) {
  UseMethod("odbcListColumns")
}

odbcListColumns.OdbcConnection <- function(connection, table, catalog = NULL, schema = NULL, ...) {

  # specify schema or catalog if given
  cols <- connection_sql_columns(connection@ptr,
    table_name = table,
    catalog_name = catalog %||% "",
    schema_name = schema %||% "")

  # extract and name fields for observer
  data.frame(
    name = cols[["name"]],
    type = cols[["field.type"]],
    stringsAsFactors = FALSE)
}

#' Preview the data in an object.
#'
#' Return the data inside an object as a data frame.
#'
#' The object to previewed must be specified as one of the arguments
#' (e.g. \code{table = "employees"}); depending on the driver and underlying
#' data store, additional specification arguments may be required.
#'
#' @param connection A connection object, as returned by `dbConnect()`.
#' @param rowLimit The maximum number of rows to display.
#' @param ... Parameters specifying the object.
#' @return A data frame containing the data in the object.
#' @export
odbcPreviewObject <- function(connection, rowLimit, ...) {
  UseMethod("odbcPreviewObject")
}

#' @export
odbcPreviewObject.OdbcConnection <- function(connection, rowLimit, table = NULL, view = NULL, schema = NULL, ...) {
  # Error if both table and view are passed
  if (!is.null(table) && !is.null(view)) {
    stop("`table` and `view` can not both be used", call. = FALSE)
  }

  # Error if neither table and view are passed
  if (is.null(table) && is.null(view)) {
    stop("`table` and `view` can not both be `NULL`", call. = FALSE)
  }

  name <- if (!is.null(table)) {
    table
  } else {
    view
  }

  # append schema if specified
  if (!is.null(schema)) {
    name <- paste(dbQuoteIdentifier(connection, schema), dbQuoteIdentifier(connection, name), sep = ".")
  }

  dbGetQuery(connection, paste("SELECT * FROM", name), n = rowLimit)
}

#' Get an icon representing a connection.
#'
#' Return the path on disk to an icon representing a connection.
#'
#' The icon returned should be a 32x32 square image file.
#'
#' @param connection A connection object, as returned by `dbConnect()`.
#' @return The path to an icon file on disk.
#' @export
odbcConnectionIcon <- function(connection) {
  UseMethod("odbcConnectionIcon")
}

#' @export
odbcConnectionIcon.default <- function(connection) {
  # no icon is returned by default
  ""
}

#' List the actions supported for the connection
#'
#' Return a list of actions that can be performed on the connection.
#'
#' The list returned is a named list of actions, where each action has the
#' following properties:
#'
#' \describe{
#'   \item{callback}{A function to be invoked to perform the action}
#'   \item{icon}{An optional path to an icon representing the action}
#' }
#'
#' @param connection A connection object, as returned by `dbConnect()`.
#' @return A named list of actions that can be performed on the connection.
#' @export
odbcConnectionActions <- function(connection) {
  UseMethod("odbcConnectionActions")
}

#' @export
odbcConnectionActions.default <- function(connection) {
  list(
    Help = list(
      # show README for this package as the help; we will update to a more
      # helpful (and/or more driver-specific) website once one exists
      icon = "",
      callback = function() {
        utils::browseURL("https://github.com/rstats-db/odbc/blob/master/README.md")
      }
    )
  )
}

on_connection_closed <- function(con) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  type <- con@info$dbms.name
  host <- con@info$dbname
  observer$connectionClosed(type, host)
}

on_connection_updated <- function(con, hint) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  type <- con@info$dbms.name
  host <- con@info$dbname
  observer$connectionUpdated(type, host, hint = hint)
}

on_connection_opened <- function(connection, code) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  # find an icon for this DBMS
  icon <- odbcConnectionIcon(connection)

  # use the database name as the display name
  display_name <- connection@info$dbname
  server_name <-connection@info$servername

  # append the server name if we know it, and it isn't the same as the database name
  # (this can happen for serverless, nameless databases such as SQLite)
  if (!is.null(server_name) && nzchar(server_name) &&
      !identical(server_name, display_name)) {
    display_name <- paste(display_name, "-", server_name)
  }

  # let observer know that connection has opened
  observer$connectionOpened(
    # connection type
    type = connection@info$dbms.name,

    # name displayed in connection pane
    displayName = display_name,

    # host key
    host = connection@info$dbname,

    # icon for connection
    icon = icon,

    # connection code
    connectCode = code,

    # disconnection code
    disconnect = function() {
      dbDisconnect(connection)
    },

    listObjectTypes = function () {
      odbcListObjectTypes(connection)
    },

    # table enumeration code
    listObjects = function(...) {
      odbcListObjects(connection, ...)
    },

    # column enumeration code
    listColumns = function(...) {
      odbcListColumns(connection, ...)
    },

    # table preview code
    previewObject = function(rowLimit, ...) {
      odbcPreviewObject(connection, rowLimit, ...)
    },

    # other actions that can be executed on this connection
    actions = odbcConnectionActions(connection),

    # raw connection object
    connectionObject = connection
  )
}
# nocov end
