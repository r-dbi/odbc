#' @include odbc.R
NULL

#' Odbc Driver Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcDriver objects.
#' @name OdbcDriver
NULL

#' Odbc driver
#'
#' Driver for an ODBC database.
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

#' Connect to a ODBC compatible database
#'
#' @inheritParams DBI::dbConnect
#' @param dsn The Data Source Name.
#' @param timezone The Server time zone. Useful if the database has an internal
#' timezone that is _not_ 'UTC'. If the database is in your local timezone set
#' to `Sys.timezone()`. See [OlsonNames()] for a complete list of available
#' timezones on your system.
#' @param encoding The Server text encoding. Used if the database has an
#' internal encoding that is _not_ `UTF-8`. If the database is in your local
#' encoding set to `""`. See [iconvlist()] for a complete list of available
#' encodings on your system.
#' @param driver The ODBC driver name.
#' @param server The server hostname.
#' @param database The database on the server.
#' @param uid The user identifer.
#' @param pwd The password to use.
#' @param ... Additional ODBC keywords, these will be joined with the other
#' arguments to form the final connection string.
#' @param .connection_string A complete connection string, useful if you are
#' copy pasting it from another source. If this argument is used any additional
#' arguments will be appended to this string.
#'
#' @details
#' The connection string keywords are driver dependant. The parameters
#' documented here are common, but some drivers may not accept them. Please see
#' the specific driver documentation for allowed parameters,
#' \url{https://www.connectionstrings.com} is also a useful resource of example
#' connection strings for a variety of databases.
#' @aliases dbConnect
#' @export
setMethod(
  "dbConnect", "OdbcDriver",
  function(drv, dsn = NULL, ..., timezone = "UTC", encoding = "UTF-8", driver = NULL, server = NULL, database = NULL,
    uid = NULL, pwd = NULL, .connection_string = NULL) {

    con <- OdbcConnection(
      dsn = dsn,
      ...,
      timezone = timezone,
      encoding = encoding,
      driver = driver,
      server = server,
      database = database,
      uid = uid,
      pwd = pwd,
      .connection_string = .connection_string)

    # perform the connection notification at the top level, to ensure that it's had
    # a chance to get its external pointer connected, and so we can capture the
    # expression that created it
    if (!is.null(getOption("connectionObserver"))) { # nocov start
      addTaskCallback(function(expr, ...) {
        tryCatch({
          if (is.call(expr) && identical(expr[[1]], as.symbol("<-"))) {
            # notify if this is an assignment we can replay
            on_connection_opened(eval(expr[[2]]), paste(
              c("library(odbc)", deparse(expr)), collapse = "\n"))
          }
        }, error = function(e) {
          warning("Could not notify connection observer. ", e$message)
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

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbcDriver", "data.frame"),
  function(dbObj, obj, ...) {
    vapply(obj, odbcDataType, con = dbObj, FUN.VALUE = character(1), USE.NAMES = TRUE)
  })

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
