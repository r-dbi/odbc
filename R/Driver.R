#' @include odbc.R
NULL

#' Odbc Driver Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcDriver objects.
#' @name OdbcDriver
NULL

#' ODBC Driver
#'
#' @description
#'
#' This function creates a driver for an ODBC database. Its output
#' is intended to be passed to [dbConnect()].
#'
#' @details
#'
#' The odbc package is one piece of the R interface to databases with support
#' for ODBC:
#'
#' ![A diagram containing four boxes with arrows linking each pointing left to right. The boxes read, in order, R interface, driver manager, ODBC driver, and database. The left-most box, R interface, contains three smaller components, labeled dbplyr, DBI, and odbc.](whole-game.png){options: width=95%}
#'
#' The package supports any **database** with ODBC support, including
#'
#' * [SQL Server](https://www.microsoft.com/en-us/sql-server/),
#' * [Oracle](https://www.oracle.com/database),
#' * [MySQL](https://www.mysql.com/),
#' * [PostgreSQL](https://www.postgresql.org/),
#' * [SQLite](https://sqlite.org/index.html),
#'
#' and others.
#'
#' Support for a given database is provided by an **ODBC driver**, which defines
#' how to interact with that database using the standardized syntax of ODBC and SQL.
#'
#' One of the central benefits of ODBC is its interoperability; any database
#' with drivers available is accessible through ODBC. To manage information
#' about these drivers and the data sources they provide access to, our
#' computers use a **driver manager**. Windows is bundled with a driver manager,
#' while MacOS and Linux require installation of one; this package supports
#' the [unixODBC](https://www.unixodbc.org/) driver manager.
#'
#' In the **R interface**, the [DBI package](https://dbi.r-dbi.org/) provides a
#' front-end while odbc implements a back-end to communicate with the driver
#' manager. The odbc package is built on top of the
#' [nanodbc](https://nanodbc.github.io/nanodbc/) C++ library.
#'
#' Interfacing with databases using R and odbc involves three high-level steps:
#'
#' 1) **Configure drivers and data sources**: the functions [odbcListDrivers()]
#'   and [odbcListDataSources()] help to interface with the driver manager.
#' 2)  **Connect to a database**: The [dbConnect()] function, called with the
#'   first argument odbc(), connects to a database using the specified ODBC
#'   driver to create a connection object.
#' 3) **Interface with connections**: The resulting connection object can be
#'   passed to various functions to retrieve information on database
#'   structure ([dbListTables()]), iteratively develop queries ([dbSendQuery()],
#'   [dbColumnInfo()]), and query data objects ([dbFetch()]).
#'
#' @export
#' @import methods DBI
#' @examples
#' \dontrun{
#' #' library(DBI)
#' odbc::odbc()
#' }
odbc <- function() {
  new("OdbcDriver")
}

#' @rdname OdbcDriver
#' @export
setClass("OdbcDriver", contains = "DBIDriver")

#' @rdname OdbcDriver
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbcDriver",
  function(object) {
    cat("<OdbcDriver>\n")
    # TODO: Print more details
  })

#' Connect to a database via an ODBC driver
#'
#' This method is invoked when [DBI::dbConnect()] is called with the first argument
#' [odbc::odbc()].
#'
#' @param drv An `OdbcDriver`, from [odbc::odbc()].
#' @param dsn The data source name. For currently available options, see the
#'   `name` column of [odbcListDataSources()] output.
#' @param timezone The server time zone. Useful if the database has an internal
#'   timezone that is _not_ 'UTC'. If the database is in your local timezone,
#'   set this argument to [Sys.timezone()]. See [OlsonNames()] for a complete
#'   list of available time zones on your system.
#' @param timezone_out The time zone returned to R. If you want to display
#'   datetime values in the local timezone, set to [Sys.timezone()].
#' @param encoding The text encoding used on the Database. If the database is
#'   not using UTF-8 you will need to set the encoding to get accurate
#'   re-encoding. See [iconvlist()] for a complete list of available encodings
#'   on your system. Note strings are always returned `UTF-8` encoded.
#' @param driver The ODBC driver name or a path to a driver. For currently
#'   available options, see the `name` column of [odbcListDrivers()] output.
#' @param server The server hostname. Some drivers use `Servername` as the name
#'   for this argument. Not required when configured for the supplied `dsn`.
#' @param database The database on the server. Not required when configured for
#'   the supplied `dsn`.
#' @param uid The user identifier. Some drivers use `username` as the name
#'   for this argument. Not required when configured for the supplied `dsn`.
#' @param pwd The password. Some drivers use `password` as the name
#'   for this argument. Not required when configured for the supplied `dsn`.
#' @param dbms.name The database management system name. This should normally
#'   be queried automatically by the ODBC driver. This name is used as the class
#'   name for the OdbcConnection object returned from [dbConnect()]. However, if
#'   the driver does not return a valid value, it can be set manually with this
#'   parameter.
#' @param attributes An S4 object of connection attributes that are passed
#'   prior to the connection being established. See \link{ConnectionAttributes}.
#' @param ... Additional ODBC keywords. These will be joined with the other
#'   arguments to form the final connection string.
#'
#'   Note that all generic ODBC parameter names, and the values of `drv` and
#'   `dsn`, are case-insensitive. The case-sensitivity of the values of generic
#'   arguments, as well as the names and values of driver-specific arguments,
#'   are determined by the driver `drv`.
#' @param .connection_string A complete connection string, useful if you are
#'   copy pasting it from another source. If this argument is used, any
#'   additional arguments will be appended to this string.
#' @param bigint The R type that `SQL_BIGINT` types should be mapped to.
#'   Default is [bit64::integer64], which allows the full range of 64 bit
#'   integers.
#' @param timeout Time in seconds to timeout the connection attempt. Setting a
#'   timeout of `Inf` indicates no timeout. Defaults to 10 seconds.
#' @details
#' The connection string keywords are driver dependent. The parameters
#' documented here are common, but some drivers may not accept them. Please see
#' the specific driver documentation for allowed parameters;
#' \url{https://www.connectionstrings.com} is also a useful resource of example
#' connection strings for a variety of databases.
#'
#' @aliases dbConnect
#' @import rlang
#' @export
setMethod(
  "dbConnect", "OdbcDriver",
  function(drv,
    dsn = NULL,
    ...,
    timezone = "UTC",
    timezone_out = "UTC",
    encoding = "",
    bigint = c("integer64", "integer", "numeric", "character"),
    timeout = 10,
    driver = NULL,
    server = NULL,
    database = NULL,
    uid = NULL,
    pwd = NULL,
    dbms.name = NULL,
    attributes = NULL,
    .connection_string = NULL) {

    con <- OdbcConnection(
      dsn = dsn,
      ...,
      timezone = timezone,
      timezone_out = timezone_out,
      encoding = encoding,
      bigint = bigint,
      timeout = timeout,
      driver = driver,
      server = server,
      database = database,
      uid = uid,
      pwd = pwd,
      dbms.name = dbms.name,
      attributes = attributes,
      .connection_string = .connection_string)

    # perform the connection notification at the top level, to ensure that it's had
    # a chance to get its external pointer connected, and so we can capture the
    # expression that created it
    if (!is.null(getOption("connectionObserver"))) { # nocov start
      addTaskCallback(function(expr, ...) {
        tryCatch({
          if (rlang::is_call(x = expr, name = c("<-", "=")) &&
              "dbConnect" %in% as.character(expr[[3]][[1]])) {

            # notify if this is an assignment we can replay
            on_connection_opened(eval(expr[[2]]), paste(
              c("library(DBI)", deparse(expr)), collapse = "\n"))
          }
        }, error = function(e) {
          warning("Could not notify connection observer. ", e$message, call. = FALSE)
        })

        # always return false so the task callback is run at most once
        FALSE
      })
    } # nocov end

    con
  }
)

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbcDriver",
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj, ...)
  })

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbcDriver", "list"),
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj, ...)
  })

odbc_data_type_df <- function(dbObj, obj, ...) {
  res <- character(NCOL(obj))
  nms <- names(obj)
  for (i in seq_along(obj)) {
    tryCatch(
      res[[i]] <- odbcDataType(con = dbObj, obj[[i]]),
      error = function(e) {
        if (conditionMessage(e) == "Unsupported type") {
          stop("Column '", nms[[i]], "' is of unsupported type: '", object_type(obj[[i]]), "'", call. = FALSE)
        } else {
          stop(e)
        }
      }
    )
  }
  names(res) <- nms
  res
}

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod("dbDataType", c("OdbcDriver", "data.frame"), odbc_data_type_df)

#' @rdname OdbcDriver
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbcDriver",
  function(dbObj, ...) {
    TRUE
  })

#' @rdname OdbcDriver
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbcDriver",
  function(dbObj, ...) {
    list(max.connections = NULL, driver.version = NULL, client.version = NULL)
  })
