
list_object_types <- function(connection) {
  UseMethod("list_object_types")
}

list_object_types.default <- function(connection) {
  # slurp all the objects in the database so we can determine the correct
  # object hierarchy
  objs <- connection_sql_tables(connection$con@ptr)

  # all databases contain tables, at a minimum
  obj_types <- list(table = list(contains = "data"))

  # see if we have views too
  if (any(objs[["table_type"]] == "VIEW")) {
    obj_types <- c(obj_types, list(view = list(contains = "data")))
  }

  # check for multiple schema or a named schema
  schemas <- unique(objs[["table_schema"]])
  if (length(schemas) > 1 || nzchar(schemas)) {
    obj_types <- list(schema = list(contains = obj_types))
  }

  # check for multiple catalogs
  catalogs <- unique(objs[["table_catalog"]])
  if (length(catalogs) > 1) {
    obj_types <- list(catalog = list(contains = obj_types))
  }

  obj_types
}

list_objects <- function(connection, ...) {
  UseMethod("list_objects")
}

list_objects.default <- function(connection, ...) {
  args <- list(...)

  # get all the matching objects
  objs <- connection_sql_tables(connection$con@ptr,
      catalog_name = if (is.null(args$catalog)) "" else args$catalog,
      schema_name = if (is.null(args$schema)) "" else args$schema)

  # if no catalog was supplied but this database has catalogs, return a list of
  # catalogs
  if (is.null(args$catalog)) {
    catalogs <- unique(objs[["table_catalog"]])
    if (length(catalogs) > 1) {
      return(data.frame(
        name = catalogs,
        type = rep("catalog", times = length(catalogs)),
        stringAsFactors = FALSE
      ))
    }
  }

  # if no schema was supplied but this database has schema, return a list of
  # schema
  if (is.null(args$schema)) {
    schema <- unique(objs[["table_schema"]])
    if (length(schema) > 1) {
      return(data.frame(
        name = schema,
        type = rep("schema", times = length(schema)),
        stringsAsFactors = FALSE))
    }
  }

  # just return a list of the objects and their types, possibly filtered by the
  # options above
  data.frame(
    name = objs[[table_name]],
    type = objs[[table_type]],
    stringsAsFactors = FALSE
  )
}

list_columns <- function(connection, ...) {
  UseMethod("list_columns")
}

list_columns.default <- function(connection, ...) {
  # default implementation: list columns in the given table
  args <- list(...)

  # read table or view as desired
  obj <- if (is.null(args$table)) args$view else args$table

  # specify schema or catalog if given
  cols <- connection_sql_columns(connection$con@ptr,
    table_name = obj,
    schema_name = if (is.null(args$schema)) "" else args$schema,
    catalog_name = if (is.null(args$catalog)) "" else args$catalog)

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
  args <- list(...)

  # read table or view as desired
  obj <- if (is.null(args$table)) args$view else args$table

  # append schema if specified
  if (!is.null(args$schema))
    obj <- paste(args$schema, obj, sep = ".")

  dbGetQuery(connection$con, paste("SELECT * FROM", obj))
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
