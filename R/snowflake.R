#' Helper for Connecting to Snowflake via ODBC
#'
#' @description
#'
#' Connect to a Snowflake account via the [Snowflake ODBC
#' driver](https://docs.snowflake.com/en/developer-guide/odbc/odbc).
#'
#' In particular, the custom `dbConnect()` method for the Snowflake ODBC driver
#' detects ambient OAuth credentials on platforms like Snowpark Container
#' Services or Posit Workbench.
#'
#' @inheritParams DBI::dbConnect
#' @param account A Snowflake [account
#'   identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier),
#'   e.g. `"testorg-test_account"`.
#' @param driver The name of the Snowflake ODBC driver, or `NULL` to use the
#'   default name.
#' @param warehouse The name of a Snowflake compute warehouse, or `NULL` to use
#'   the default.
#' @param database The name of a Snowflake database, or `NULL` to use the
#'   default.
#' @param schema The name of a Snowflake database schema, or `NULL` to use the
#'   default.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Snowflake
#'   account.
#'
#' @examples
#' \dontrun{
#' # Use ambient credentials.
#' DBI::dbConnect(odbc::snowflake())
#'
#' # Use browser-based SSO (if configured). Only works on desktop.
#' DBI::dbConnect(
#'   odbc::snowflake(),
#'   account = "testorg-test_account",
#'   authenticator = "externalbrowser"
#' )
#'
#' # Use a traditional username & password.
#' DBI::dbConnect(
#'   odbc::snowflake(),
#'   account = "testorg-test_account",
#'   uid = "me",
#'   pwd = rstudioapi::askForPassword()
#' )
#' }
#' @export
snowflake <- function() {
  new("SnowflakeOdbcDriver")
}

setClass("SnowflakeOdbcDriver", contains = "OdbcDriver")

#' @rdname snowflake
#' @export
setMethod(
  "dbConnect", "SnowflakeOdbcDriver",
  function(drv,
           account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
           driver = NULL,
           warehouse = NULL,
           database = NULL,
           schema = NULL,
           ...) {
    args <- snowflake_args(
      account = account,
      driver = driver,
      warehouse = warehouse,
      database = database,
      schema = schema,
      ...
    )
    inject(dbConnect(odbc(), !!!args))
  }
)

snowflake_args <- function(account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
                           driver = NULL,
                           ...) {
  args <- list(
    driver = driver %||% snowflake_default_driver(),
    account = account,
    server = snowflake_server(account),
    application = snowflake_user_agent(),
    # Connections to Snowflake are always over HTTPS.
    port = 443
  )
  auth <- snowflake_auth_args(account)
  all <- c(args, auth, ...)

  arg_names <- tolower(names(all))
  if (!"authenticator" %in% arg_names && !all(c("uid", "pwd") %in% arg_names)) {
    warn(
      c(
        "x" = "Failed to detect ambient Snowflake credentials.",
        "i" = "Supply `uid` or `pwd` to authenticate manually."
      ),
      call = quote(DBI::dbConnect())
    )
  }

  all
}

# Returns a sensible driver name even if odbc.ini and odbcinst.ini do not
# contain an entry for the Snowflake ODBC driver. For Linux and macOS we
# default to known shared library paths used by the official installers.
# On Windows we use the official driver name.
snowflake_default_driver <- function() {
  default_paths <- snowflake_default_driver_paths()
  if (length(default_paths) > 0) {
    return(default_paths[1])
  }

  fallbacks <- c("Snowflake", "SnowflakeDSIIDriver")
  fallbacks <- intersect(fallbacks, odbcListDrivers()$name)
  if (length(fallbacks) > 0) {
    return(fallbacks[1])
  }

  abort(
    c(
      "Failed to automatically find Snowflake ODBC driver.",
      i = "Set `driver` to known driver name or path."
    ),
    call = quote(DBI::dbConnect())
  )
}

snowflake_default_driver_paths <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    paths <- c(
      "/opt/rstudio-drivers/snowflake/bin/lib/libsnowflakeodbc_sb64.so",
      "/usr/lib/snowflake/odbc/lib/libSnowflake.so"
    )
  } else if (Sys.info()["sysname"] == "Darwin") {
    paths <- "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib"
  } else {
    paths <- character()
  }
  paths[file.exists(paths)]
}

snowflake_server <- function(account) {
  if (nchar(account) == 0) {
    abort(
      c(
        "No Snowflake account ID provided.",
        i = "Either supply `account` argument or set env var `SNOWFLAKE_ACCOUNT`."
      ),
      call = quote(DBI::dbConnect())
    )
  }
  paste0(account, ".snowflakecomputing.com")
}

snowflake_user_agent <- function() {
  user_agent <- "r_odbc"
  if (nchar(Sys.getenv("SNOWFLAKE_APPLICATION")) != 0) {
    # Respect the existing user-agent if present. Normally we'd append, but the
    # Snowflake ODBC driver does not yet support space-separated entries in
    # this field.
    user_agent <- Sys.getenv("SNOWFLAKE_APPLICATION")
  }
  user_agent
}

snowflake_auth_args <- function(account) {
  # Check for Workbench-provided credentials.
  if (exists(".rs.api.getSnowflakeToken")) {
    getSnowflakeToken <- get(".rs.api.getSnowflakeToken")
    token <- getSnowflakeToken(account)
    if (!is.null(token)) {
      return(list(authenticator = "oauth", token = token))
    }
  }

  # Check for the default token mounted when running in Snowpark Container
  # Services.
  if (file.exists("/snowflake/session/token")) {
    return(list(
      authenticator = "oauth",
      token = readLines("/snowflake/session/token", warn = FALSE)
    ))
  }

  list()
}
