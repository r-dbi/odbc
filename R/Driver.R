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
#' to [Sys.timezone()]. See [OlsonNames()] for a complete list of available
#' timezones on your system.
#' @param timezone_out The time zone returned to R. If you want to display
#' datetime values in the local timezone, set to `Sys.timezone()`.
#' @param encoding The text encoding used on the Database. If the database is
#' not using UTF-8 you will need to set the encoding to get accurate re-encoding.
#' See [iconvlist()] for a complete list of available encodings on your system.
#' Note strings are always returned `UTF-8` encoded.
#' @param driver The ODBC driver name.
#' @param server The server hostname.
#' @param database The database on the server.
#' @param uid The user identifier.
#' @param pwd The password to use.
#' @param dbms.name The database management system name. This should normally
#' be queried automatically by the ODBC driver. This name is used as the class
#' name for the OdbcConnect object returned from `dbConnect()`. However if the
#' driver does not return a valid value it can be set manually with this
#' parameter.
#' @param attributes An S4 object of connection attributes that are passed
#' prior to the connection being established.  See \link{ConnectionAttributes}.
#' @param ... Additional ODBC keywords, these will be joined with the other
#' arguments to form the final connection string.
#' @param .connection_string A complete connection string, useful if you are
#' copy pasting it from another source. If this argument is used any additional
#' arguments will be appended to this string.
#' @param bigint The R type that `SQL_BIGINT` types should be mapped to,
#' default is [bit64::integer64], which allows the full range of 64 bit
#' integers.
#' @param timeout Time in seconds to timeout the connection attempt. Setting a
#' timeout of `Inf` indicates no timeout. (defaults to 10 seconds).
#' @details
#' The connection string keywords are driver dependent. The parameters
#' documented here are common, but some drivers may not accept them. Please see
#' the specific driver documentation for allowed parameters,
#' \url{https://www.connectionstrings.com} is also a useful resource of example
#' connection strings for a variety of databases.
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
