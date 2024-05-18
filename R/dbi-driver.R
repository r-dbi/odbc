#' Odbc Driver Methods
#'
#' Implementations of pure virtual functions defined in the `DBI` package
#' for OdbcDriver objects.
#' @name OdbcDriver
#' @keywords internal
NULL

#' @rdname dbConnect-OdbcDriver-method
#' @export
#' @import methods DBI
odbc <- function() {
  new("OdbcDriver")
}

#' @rdname OdbcDriver
#' @export
setClass("OdbcDriver", contains = "DBIDriver")

#' @rdname OdbcDriver
#' @inheritParams methods::show
#' @export
setMethod("show", "OdbcDriver",
  function(object) {
    cat("<OdbcDriver>\n")
    # TODO: Print more details
  }
)

#' Connect to a database via an ODBC driver
#'
#' The `dbConnect()` method documented here is invoked when [DBI::dbConnect()]
#' is called with the first argument `odbc()`. Connecting to a database via
#' an ODBC driver is likely the first step in analyzing data using the odbc
#' package; for an overview of package concepts, see the *Overview* section
#' below.
#'
#' @param drv An `OdbcDriver`, from `odbc()`.
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
#' @param attributes A list of connection attributes that are passed
#'   prior to the connection being established. See \link{ConnectionAttributes}.
#' @param interruptible Logical.  If `TRUE` calls to `SQLExecute` and
#'   `SQLExecuteDirect` can be interrupted when the user sends SIGINT ( ctrl-c ).
#'   Otherwise, they block.  Defaults to `TRUE`.  It can be set either by
#'   manipulating this argument, or setting the global option `odbc.interruptible`
#'   to `FALSE`.
#' @param ... Additional ODBC keywords. These will be joined with the other
#'   arguments to form the final connection string.
#'
#'   Note that ODBC parameter names are case-insensitive so that (e.g.) `DRV`
#'   and `drv` are equivalent. Since this is different to R and a possible
#'   source of confusion, odbc will error if you supply multiple arguments that
#'   have the same name when case is ignored.
#'
#'   Any values containing a leading or trailing space, a `=`, `;`, `{`,
#'   or `}` are likely to require quoting. Use [quote_value()] for a fairly
#'   standard approach or see your driver documentation for specifics.
#' @param .connection_string A complete connection string, useful if you are
#'   copy pasting it from another source. If this argument is used, any
#'   additional arguments will be appended to this string.
#' @param bigint The R type that `SQL_BIGINT` types should be mapped to.
#'   Default is [bit64::integer64], which allows the full range of 64 bit
#'   integers.
#' @param timeout Time in seconds to timeout the connection attempt. Setting a
#'   timeout of `Inf` indicates no timeout. Defaults to 10 seconds.
#'
#' @section Connection strings:
#'
#' Internally, `dbConnect()` creates a connection string using the supplied
#' arguments. Connection string keywords are driver-dependent; the arguments
#' documented here are common, but some drivers may not accept them.
#'
#' Alternatively to configuring DSNs and driver names with the driver manager,
#' you can pass a complete connection string directly as the
#' `.connection_string` argument.
#' [The Connection Strings Reference](https://www.connectionstrings.com) is a
#' useful resource that has example connection strings for a large variety of
#' databases.
#'
#' @section Overview:
#'
#' The odbc package is one piece of the R interface to databases with support
#' for ODBC:
#'
#' ![A diagram containing four boxes with arrows linking each pointing left to
#' right. The boxes read, in order, R interface, driver manager, ODBC driver,
#' and database. The left-most box, R interface, contains three smaller
#' components, labeled dbplyr, DBI, and odbc.](whole-game.png){options: width=95%}
#'
#' The package supports any **Database Management System (DBMS)** with ODBC
#' support. Support for a given DBMS is provided by an **ODBC driver**, which
#' defines how to interact with that DBMS using the standardized syntax of ODBC
#' and SQL. Drivers can be downloaded from the DBMS vendor or, if you're a Posit
#' customer, using the [professional drivers](https://docs.posit.co/pro-drivers/).
#' To manage information about each driver and the data sources they provide
#' access to, our computers use a **driver manager**. Windows is bundled with
#' a driver manager, while MacOS and Linux require installation of one; this
#' package supports the [unixODBC](https://www.unixodbc.org/) driver manager.
#'
#' In the **R interface**, the [DBI package](https://dbi.r-dbi.org/) provides a
#' front-end while odbc implements a back-end to communicate with the driver
#' manager. The odbc package is built on top of the
#' [nanodbc](https://nanodbc.github.io/nanodbc/) C++ library.
#'
#' Interfacing with DBMSs using R and odbc involves three high-level steps:
#'
#' 1) *Configure drivers and data sources*: the functions [odbcListDrivers()]
#'   and [odbcListDataSources()] help to interface with the driver manager.
#' 2) *Connect to a database*: The [dbConnect()] function, called with the
#'   first argument odbc(), connects to a database using the specified ODBC
#'   driver to create a connection object.
#' 3) *Interface with connections*: The resulting connection object can be
#'   passed to various functions to retrieve information on database
#'   structure ([dbListTables()]), iteratively develop queries ([dbSendQuery()],
#'   [dbColumnInfo()]), and query data objects ([dbFetch()]).
#'
#' @aliases dbConnect odbc
#'
#' @section Learn more:
#'
#' To learn more about databases:
#'
#' * ["Best Practices in Working with Databases"](https://solutions.posit.co/connections/db/)
#'   documents how to use the odbc package with various popular databases.
#' * [The pyodbc "Drivers and Driver Managers" Wiki](https://github.com/mkleehammer/pyodbc/wiki/Drivers-and-Driver-Managers)
#'   provides further context on drivers and driver managers.
#' * [Microsoft's "Introduction to ODBC"](https://learn.microsoft.com/en-us/sql/odbc/reference)
#'   is a thorough resource on the ODBC interface.
#'
#' @import rlang
#' @export
setMethod("dbConnect", "OdbcDriver",
  function(
      drv,
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
      interruptible = getOption("odbc.interruptible", TRUE),
      .connection_string = NULL) {
    check_string(dsn, allow_null = TRUE)
    check_string(timezone, allow_null = TRUE)
    check_string(timezone_out, allow_null = TRUE)
    check_string(encoding, allow_null = TRUE)
    arg_match(bigint)
    check_number_decimal(timeout, allow_null = TRUE, allow_na = TRUE)
    check_string(driver, allow_null = TRUE)
    check_string(server, allow_null = TRUE)
    check_string(database, allow_null = TRUE)
    check_string(uid, allow_null = TRUE)
    check_string(pwd, allow_null = TRUE)
    check_string(dbms.name, allow_null = TRUE)
    check_bool(interruptible)

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
      interruptible = interruptible,
      .connection_string = .connection_string
    )

    # perform the connection notification at the top level, to ensure that it's had
    # a chance to get its external pointer connected, and so we can capture the
    # expression that created it
    if (!is.null(getOption("connectionObserver"))) { # nocov start
      addTaskCallback(function(expr, ...) {
        tryCatch(
          {
            if (rlang::is_call(x = expr, name = c("<-", "=")) &&
              "dbConnect" %in% as.character(expr[[3]][[1]])) {
              # notify if this is an assignment we can replay
              on_connection_opened(eval(expr[[2]]), paste(
                c("library(DBI)", deparse(expr)),
                collapse = "\n"
              ))
            }
          },
          error = function(e) {
            warning("Could not notify connection observer. ", e$message, call. = FALSE)
          }
        )

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
setMethod("dbDataType", "OdbcDriver",
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj, ...)
  }
)

#' @rdname OdbcDriver
#' @inheritParams DBI::dbDataType
#' @export
setMethod("dbDataType", c("OdbcDriver", "list"),
  function(dbObj, obj, ...) {
    odbcDataType(dbObj, obj, ...)
  }
)

odbc_data_type_df <- function(dbObj, obj, ...) {
  res <- character(NCOL(obj))
  nms <- names(obj)
  for (i in seq_along(obj)) {
    withCallingHandlers(
      res[[i]] <- odbcDataType(con = dbObj, obj[[i]]),
      error = function(err) {
        cli::cli_abort("Can't determine type for column {nms[[i]]}.", parent = err, call = quote(odbcDataType()))
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
setMethod("dbIsValid", "OdbcDriver",
  function(dbObj, ...) {
    TRUE
  }
)

#' @rdname OdbcDriver
#' @inheritParams DBI::dbGetInfo
#' @export
setMethod("dbGetInfo", "OdbcDriver",
  function(dbObj, ...) {
    list(max.connections = NULL, driver.version = NULL, client.version = NULL)
  }
)
