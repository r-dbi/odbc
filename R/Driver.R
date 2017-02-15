#' @include odbc.R
NULL

#' Odbc Driver Methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package
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
#' Odbc::Odbc()
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
#' @param timezone The Server Time Zone. If the server has an internal timezone
#' that is _not_ 'UTC', this will be used to set the `tzone` attribute for the
#' returned `POSIXct` object.
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
#' @export
setMethod(
  "dbConnect", "OdbcDriver",
  function(drv, dsn = NULL, ..., timezone = "", driver = NULL, server = NULL, database = NULL,
    uid = NULL, pwd = NULL, .connection_string = NULL) {

    OdbcConnection(
      dsn = dsn,
      ...,
      timezone = timezone,
      driver = driver,
      server = server,
      database = database,
      uid = uid,
      pwd = pwd,
      .connection_string = .connection_string)
  }
)

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbcDriver",
  function(dbObj, obj, ...) {
    get_data_type(dbObj, obj, ...)
  })

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbcDriver", "list"),
  function(dbObj, obj, ...) {
    get_data_type(dbObj, obj, ...)
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
