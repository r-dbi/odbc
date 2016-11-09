#' @include odbconnect.R
NULL

#' Odbconnect Driver Methods
#'
#' Implementations of pure virtual functions defined in the \code{DBI} package
#' for OdbconnectDriver objects.
#' @name OdbconnectDriver
NULL

#' Odbconnect driver
#'
#' Driver for an ODBC database.
#'
#' @export
#' @import methods DBI
#' @examples
#' \dontrun{
#' #' library(DBI)
#' Odbconnect::Odbconnect()
#' }
odbconnect <- function() {
  new("OdbconnectDriver")
}

#' @rdname OdbconnectDriver
#' @export
setClass("OdbconnectDriver", contains = "DBIDriver")

#' @rdname OdbconnectDriver
#' @inheritParams methods::show
#' @export
setMethod(
  "show", "OdbconnectDriver",
  function(object) {
    cat("<OdbconnectDriver>\n")
    # TODO: Print more details
  })

#' Connect to a ODBC compatible database
#'
#' @inheritParams DBI::dbConnect
#' @param dsn The Data Source Name.
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
  "dbConnect", "OdbconnectDriver",
  function(drv, dsn = NULL, ..., driver = NULL, server = NULL, database = NULL, uid = NULL, pwd = NULL) {
    OdbconnectConnection(dsn = dsn, ..., driver = driver, server = server, database = database, uid = uid, pwd = pwd)
  }
)

#' @rdname OdbconnectDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", "OdbconnectDriver",
  function(dbObj, obj, ...) {
    get_data_type(dbObj, obj, ...)
  })

#' @rdname OdbconnectDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod(
  "dbDataType", c("OdbconnectDriver", "list"),
  function(dbObj, obj, ...) {
    get_data_type(dbObj, obj, ...)
  })

#' @rdname OdbconnectDriver
#' @inheritParams DBI::dbIsValid
#' @export
setMethod(
  "dbIsValid", "OdbconnectDriver",
  function(dbObj, ...) {
    TRUE
  })

#' @rdname OdbconnectDriver
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod(
  "dbGetInfo", "OdbconnectDriver",
  function(dbObj, ...) {
    list(max.connections = NULL, driver.version = NULL, client.version = NULL)
  })
