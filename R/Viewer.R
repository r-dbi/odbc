# given an environment and a host, return the name of an open odbc connection
find_object <- function(env, host) {
  objs <- ls(env)
  for (name in objs) {
    x <- base::get(name, envir = env)
    if (inherits(x, "OdbcConnection") &&
        identical(to_host(x), host) &&
        dbIsValid(con)) {
      return(name)
    }
  }
}

# connection-specific actions possible with odbc connections
odbc_actions <- function() {
  icons <- system.file(file.path("icons"), package = "odbc")
  list(
    Help = list(
      icon = file.path(icons, "help.png"),
      callback = function() {
        utils::browseURL("https://github.com/rstats-db/odbc")
      }
    )
  )
}

on_connection_opened <- function(con, env, parentCall) {
  parentCall[[1]] <- as.symbol("dbConnect")
  parentCall[["drv"]] <- quote(odbc::odbc())
  connectCall <- paste("library(DBI)",
                       paste("con <-", deparse(parentCall, width.cutoff = 500), collapse = " "),
                       sep = "\n")

  observer <- getOption("connectionObserver")
  if (!is.null(observer)) {
    host <- to_host(con)
    observer$connectionOpened(
      # connection type
      type = "ODBC",

      # name displayed in connection pane
      displayName = to_host_display(con),

      # host key
      host = host,

      # icon for connection
      # TODO: icon = system.file(file.path("icons", "odbc.png"), package = "odbc"),

      # connection code
      connectCode = connectCall,

      # disconnection code
      disconnectCode = function() {
        name <- find_object(env, host)
        if (!is.null(name))
          paste0("dbDisconnect(", name, ")")
        else
          ""
      },

      # table enumeration code
      listTables = function() {
        connection_list_tables(con)
      },

      # column enumeration code
      listColumns = function(table) {
        connection_list_columns(con, table)
      },

      # table preview code
      previewTable = function(table, rowLimit) {
        connection_preview_table(con, table, rowLimit)
      },

      # other actions that can be executed on this connection
      actions = odbc_actions()
    )
  }
}

# return the external connection viewer (or NULL if none active)
external_viewer <- function() {
  viewer <- getOption("connectionObserver")
  if (is.null(viewer))
    getOption("connectionViewer")
  else
    viewer
}

on_connection_closed <- function(con) {
  viewer <- external_viewer()
  if (!is.null(viewer))
    viewer$connectionClosed(type = "ODBC", host = to_host(con))
}

on_connection_updated <- function(con, hint) {
  viewer <- external_viewer()
  if (!is.null(viewer))
    viewer$connectionUpdated(type = "ODBC", host = to_host(con), hint = hint)
}

connection_list_tables <- function(con) {
  if (is.null(con) || !dbIsValid(con))
    character()
  else
    sort(dbListTables(con))
}

connection_list_columns <- function(con, table) {
  if (is.null(con) || !dbIsValid(con)) {
    NULL
  } else {
    sql <- paste("SELECT * FROM", table, "LIMIT 5")
    df <- dbGetQuery(con, sql)
    data.frame(
      name = names(df),
      type = as.character(lapply(names(df), function(f) {
        capture.output(str(df[[f]],
                           give.length = FALSE,
                           width = 30,
                           strict.width = "cut"))
      })),
      stringsAsFactors = FALSE
    )
  }
}

connection_preview_table <- function(con, table, limit) {
  if (is.null(con) || !dbIsValid(con)) {
    NULL
  } else {
    sql <- paste("SELECT * FROM", table, "LIMIT", limit)
    dbGetQuery(con, sql)
  }
}

# function to generate host display name
to_host_display <- function(con) {
  if (is.null(con)) {
    NULL
  }
  else {
    dbname <- dbGetInfo(con)$dbname

    parsedRegExp <- regexec("(Data Source|Database)=([^;]*)+", dbname)
    parsed <- regmatches(dbname, parsedRegExp)
    if (length(parsed) != 1) {
      dbname
    }
    else {
      parsed <- parsed[[1]]
      if (length(parsed) != 3) dbname else parsed[[3]]
    }
  }
}

# function to connection to host
to_host <- function(con) {
  if (dbIsValid(con)) {
    paste(dbGetInfo(con), collapse = "|")
  } else {
    NULL
  }
}
