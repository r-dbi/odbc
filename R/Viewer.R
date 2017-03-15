
list_object_types <- function(connection) {
  UseMethod("list_object_types")
}

list_object_types.default <- function(connection) {
  # default implementation: only tables are returned
  return(list(
    table = list(contains = "data")))
}

list_objects <- function(connection, ...) {
  UseMethod("list_objects")
}

list_objects.default <- function(connection, ...) {
  # default implementation: list all the objects in the database
  dbListTables(connection$con)
}

list_columns <- function(connection, ...) {
  UseMethod("list_columns")
}

list_columns.default <- function(connection, ...) {
  # default implementation: list columns in the given table
  args <- list(...)
  cols <- connection_sql_columns(connection$con@ptr,
    table_name = args$table)

  # extract and name fields for observer
  data.frame(
    name = cols[["name"]],
    type = cols[["field.type"]],
    stringsAsFactors = FALSE)
}

preview_object <- function(connection, rowLimit, ...) {
  UseMethod("preview_object")
}

preview_object.default <- function(connection, rowLimit, ...) {
  # default implementation: read the table
  args <- list(...)
  dbReadTable(connection$con, args$table)
}

connection_icon <- function(connection) {
  UseMethod("connection_icon")
}

connection_icon.default <- function(connection) {
  # default implementation: use default icon
  system.file(file.path("icons", "ODBC.png"), package = "odbc")
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

on_connection_opened <- function(con, code) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  # wrap the S4 connection object in an S3 object which understands the
  # connection type for dispatch
  connection <- structure(
    list(con = con),
    class = con@info$dbms.name
  )

  # find an icon for this DBMS
  icon <- connection_icon(connection)

  # let observer know that connection has opened
  observer$connectionOpened(
    # connection type
    type = con@info$dbms.name,

    # name displayed in connection pane
    displayName = con@info$dbname,

    # host key
    host = con@info$dbname,

    # icon for connection
    icon = icon,

    # connection code
    connectCode = code,

    # disconnection code
    disconnect = function() {
      dbDisconnect(con)
    },

    listObjectTypes = function () {
      list_object_types(connection)
    },

    # table enumeration code
    listObjects = function(...) {
      list_objects(connection, ...)
    },

    # column enumeration code
    listColumns = function(...) {
      list_columns(connection, ...)
    },

    # table preview code
    previewObject = function(rowLimit, ...) {
      preview_object(connection, rowLimit, ...)
    },

    # other actions that can be executed on this connection
    actions = list(),

    # raw connection object
    connectionObject = con
  )
}
