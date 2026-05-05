#' @include dbi-connection.R
NULL

#' @export
#' @rdname DBI-classes
setClass("Snowflake", contains = "OdbcConnection")

#' getCatalogSchema
#'
#' Internal, Snowflake specific method that will return a list
#' where `catalog_name` and `schema_name` are either the arguments
#' passed by the user ( if not null ), or if null, the CURRENT
#' database ( or schema, respectively ).
#' @noRd
getCatalogSchema <- function(conn, catalog_name = NULL, schema_name = NULL) {
  if(is.null(catalog_name) || is.null(schema_name)) {
    res <- dbGetQuery(conn, "SELECT CURRENT_DATABASE() AS CAT, CURRENT_SCHEMA() AS SCH")
    if(is.null(catalog_name) && !is.na(res$CAT)) {
      catalog_name <- res$CAT
    }
    if(is.null(schema_name) && !is.na(res$SCH)) {
      schema_name <- res$SCH
    }
  }
  return(list(catalog_name = catalog_name, schema_name = schema_name))
}

#' Connecting to Snowflake via ODBC
#'
#' @description
#' ## `odbcConnectionColumns()`
#'
#' If the catalog, or the schema arguments are NULL, attempt to infer
#' by querying for CURRENT_DATABASE() and CURRENT_SCHEMA().  We do this
#' to aid with performance, as the SQLColumns method is more performant
#' when restricted to a particular DB/schema.
#' @param conn A [DBI::DBIConnection-class] object, as returned by
#' `dbConnect()`.
#' @inheritParams DBI::dbListFields
#' @param catalog_name,schema_name Catalog and schema names.
#' @rdname driver-Snowflake
#' @usage NULL
setMethod("odbcConnectionColumns", c("Snowflake", "character"),
  function(conn,
           name,
           ...,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
    catSchema <- getCatalogSchema(conn, catalog_name, schema_name)

    callNextMethod(conn = conn, name = name, ..., catalog_name = catSchema$catalog_name,
      schema_name = catSchema$schema_name, column_name = column_name, exact = exact)
  }
)

#' @rdname driver-Snowflake
setMethod("dbExistsTableForWrite", c("Snowflake", "character"),
  function(conn, name, ...,
           catalog_name = NULL, schema_name = NULL) {
    catSchema <- getCatalogSchema(conn, catalog_name, schema_name)
    catalog_name <- catSchema$catalog_name
    schema_name <- catSchema$schema_name

    callNextMethod(conn = conn, name = name, ...,
      catalog_name = catalog_name, schema_name = schema_name)
  }
)

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Snowflake",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = "VARCHAR",
      datetime = "TIMESTAMP",
      date = "DATE",
      time = "TIME",
      binary = "BINARY",
      integer = "INTEGER",
      int64 = "INTEGER",
      double = "FLOAT",
      character = "VARCHAR",
      logical = "BOOLEAN",
      list = "VARCHAR",
      stop("Unsupported type", call. = FALSE)
    )
  }
)

#' Helper for connecting to Snowflake via ODBC
#'
#' @description
#'
#' Connect to a Snowflake account via the [Snowflake ODBC
#' driver](https://docs.snowflake.com/en/developer-guide/odbc/odbc).
#'
#' In particular, the custom `dbConnect()` method for the Snowflake ODBC driver
#' supports the `connections.toml` and `config.toml` files used by the Snowflake
#' Connector for Python and the Snowflake CLI via the \pkg{snowflakeauth}
#' package. It also detects ambient OAuth credentials on platforms like Snowpark
#' Container Services or Posit Workbench. Finally, it can detect viewer-based
#' credentials on Posit Connect if the \pkg{connectcreds} package is installed.
#'
#' In addition, on macOS platforms, the `dbConnect` method will check and warn
#' if it detects irregularities with how the driver is configured, unless the
#' `odbc.no_config_override` environment variable is set.
#'
#' @param drv an object that inherits from [DBI::DBIDriver-class],
#' or an existing [DBI::DBIConnection-class]
#' object (in order to clone an existing connection).
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
#' @param uid,pwd Manually specify a username and password for authentication.
#'   Specifying these options will disable ambient credential discovery.
#' @param connection_name The name of a connection defined in your Snowflake
#'   `connections.toml` file, or `NULL` to use the default connection.
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
#'
#' # Use a named connection from a connections.toml file.
#' DBI::dbConnect(odbc::snowflake(), connection_name = "test")
#'
#' # Use credentials from the viewer (when possible) in a Shiny app
#' # deployed to Posit Connect.
#' library(connectcreds)
#' server <- function(input, output, session) {
#'   conn <- DBI::dbConnect(odbc::snowflake())
#' }
#' }
#' @export
snowflake <- function() {
  new("SnowflakeOdbcDriver")
}

#' @rdname snowflake
#' @export
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
           uid = NULL,
           pwd = NULL,
           connection_name = NULL,
           ...) {
    call <- caller_env()
    check_string(account, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(warehouse, allow_null = TRUE, call = call)
    check_string(database, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)
    check_string(connection_name, allow_null = TRUE, call = call)
    args <- snowflake_args(
      account = account,
      driver = driver,
      warehouse = warehouse,
      database = database,
      schema = schema,
      uid = uid,
      pwd = pwd,
      connection_name = connection_name,
      ...
    )
    # Perform some sanity checks on MacOS
    configure_simba(snowflake_simba_config(args$driver),
      action = "modify")
    inject(dbConnect(odbc(), !!!args))
  }
)

snowflake_args <- function(account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
                           driver = NULL,
                           ...) {
  auth <- snowflake_auth_args(account, ...)
  host <- auth$.host
  auth$.host <- NULL
  if (!is.null(auth$.account)) {
    account <- auth$.account
  }
  auth$.account <- NULL

  args <- list(
    driver = driver %||% snowflake_default_driver(),
    account = account,
    server = snowflake_server(account, host = host),
    # Connections to Snowflake are always over HTTPS.
    port = 443
  )
  dots <- list(...)
  dots$connection_name <- NULL
  dots <- compact(dots)
  all <- utils::modifyList(c(args, auth), dots)

  # Set application value and respect the Snowflake Partner environment variable, if present.
  if (is.null(all$application)) {
    if (nchar(Sys.getenv("SF_PARTNER")) != 0 ){
      all$application <- Sys.getenv("SF_PARTNER")
    } else {
      all$application <- "r-odbc"
    }
  }

  arg_names <- tolower(names(all))
  if (!"authenticator" %in% arg_names && !all(c("uid", "pwd") %in% arg_names)) {
    msg <- c(
      "Failed to detect ambient Snowflake credentials.",
      "i" = "Supply {.arg uid} and {.arg pwd} to authenticate manually."
    )
    if (running_on_connect()) {
      msg <- c(
        msg,
        "i" = "Or consider enabling Posit Connect's Snowflake integration \
              for viewer-based credentials. See {.url \
              https://docs.posit.co/connect/user/oauth-integrations/#adding-oauth-integrations-to-deployed-content}
              for details."
      )
    }
    cli::cli_abort(msg, call = quote(DBI::dbConnect()))
  }

  all
}

# Returns a sensible driver name even if odbc.ini and odbcinst.ini do not
# contain an entry for the Snowflake ODBC driver. For Linux and macOS we
# default to known shared library paths used by the official installers.
# On Windows we use the official driver name.
snowflake_default_driver <- function() {
  find_default_driver(
    snowflake_default_driver_paths(),
    fallbacks = c("Snowflake", "SnowflakeDSIIDriver"),
    label = "Snowflake",
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
    paths <- c(
      "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib",
      "/opt/snowflake-osx-x64/bin/lib/libsnowflakeodbc_sb64-universal.dylib"
    )
  } else {
    paths <- character()
  }
  paths
}

snowflake_simba_config <- function(driver) {
  snowflake_env <- Sys.getenv("SIMBASNOWFLAKEINI")
  URL <- "https://docs.snowflake.com/en/developer-guide/odbc/odbc-download"
  if (!identical(snowflake_env, "")) {
    return(list(path = snowflake_env, url = URL))
  }
  # Posit configuration is likely at:
  # /opt/snowflake-osx-x64/bin/lib/rstudio.snowflakeodbc.ini
  # OEM configuration is likely at:
  # /opt/snowflake/snowflakeodbc/lib/universal/simba.snowflake.ini
  common_dirs <- c(
    driver_dir(driver),
    "/opt/snowflake-osx-x64/bin/lib/",
    "/opt/snowflake/snowflakeodbc/lib/universal/",
    getwd(),
    Sys.getenv("HOME")
  )
  return(list(
    path = list.files(
      common_dirs,
      pattern = "snowflake(odbc)?\\.ini$",
      full.names = TRUE),
    url = URL
  ))
}

snowflake_server <- function(account, host = NULL) {
  if (!is.null(host) && nzchar(host)) {
    return(host)
  }
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

snowflake_auth_args <- function(account,
                                uid = NULL,
                                pwd = NULL,
                                authenticator = NULL,
                                connection_name = NULL,
                                ...) {
  check_string(authenticator, allow_null = TRUE)
  # Detect viewer-based credentials from Posit Connect.
  url <- paste0("https://", account, ".snowflakecomputing.com")
  if (is_installed("connectcreds") && connectcreds::has_viewer_token(url)) {
    token <- connectcreds::connect_viewer_token(url)
    return(list(authenticator = "oauth", token = token$access_token))
  }

  if (!is.null(uid) &&
      # allow for uid without pwd for alt auth (#817, #889)
      (!is.null(pwd) ||
       isTRUE(authenticator %in% c("externalbrowser", "SNOWFLAKE_JWT")))) {
    return(list(uid = uid, pwd = pwd))
  } else if (xor(is.null(uid), is.null(pwd))) {
    abort(
      c(
        "Both `uid` and `pwd` must be specified to authenticate.",
        i = "Or leave both unset to use ambient Snowflake credentials."
      ),
      call = quote(DBI::dbConnect())
    )
  }

  # Manual override of the authentication method.
  if (!is.null(authenticator)) {
    return(list())
  }

  check_installed("snowflakeauth")
  sf_args <- list(name = connection_name)
  dots <- list(...)
  sf_params <- c(
    "user", "role", "schema", "database", "warehouse", "authenticator",
    "private_key", "private_key_file", "private_key_path",
    "private_key_file_pwd", "token", "token_file_path", "password", "host"
  )
  dots <- compact(dots)
  sf_args <- c(sf_args, dots[intersect(names(dots), sf_params)])
  if (file.exists("/snowflake/session/token") &&
      is.null(sf_args$token_file_path) &&
      is.null(sf_args$token)) {
    sf_args$token_file_path <- "/snowflake/session/token"
  }
  # Don't pass `account` so we can compare it to what snowflakeauth resolves.
  conn <- inject(snowflakeauth::snowflake_connection(!!!sf_args))
  if (is.null(connection_name) &&
      nzchar(account) && !is.null(conn$account) &&
      !identical(account, conn$account)) {
    cli::cli_abort(
      c(
        "Snowflake account mismatch: requested {.val {account}} but
         connection {.val {conn$name %||% 'default'}} resolved
         {.val {conn$account}}.",
        "i" = "Check your {.file connections.toml} or pass the correct
              {.arg account}."
      ),
      call = quote(DBI::dbConnect())
    )
  }
  snowflake_connection_to_odbc_args(conn)
}

snowflake_connection_to_odbc_args <- function(conn) {
  args <- list()

  if (!is.null(conn$user)) {
    args$uid <- conn$user
  }
  if (!is.null(conn$password)) {
    args$pwd <- unclass(conn$password)
  }
  if (!is.null(conn$token)) {
    args$token <- unclass(conn$token)
  }
  if (!is.null(conn$token_file_path)) {
    args$token_file_path <- conn$token_file_path
  }
  if (!is.null(conn$authenticator) && conn$authenticator != "snowflake") {
    args$authenticator <- conn$authenticator
  }

  priv_key <- conn$private_key_file %||%
    conn$private_key %||%
    conn$private_key_path
  if (!is.null(priv_key)) {
    args$priv_key_file <- priv_key
  }
  if (!is.null(conn$private_key_file_pwd)) {
    args$priv_key_file_pwd <- unclass(conn$private_key_file_pwd)
  }

  if (!is.null(conn$warehouse)) args$warehouse <- conn$warehouse
  if (!is.null(conn$database)) args$database <- conn$database
  if (!is.null(conn$schema)) args$schema <- conn$schema
  if (!is.null(conn$role)) args$role <- conn$role
  if (!is.null(conn$workload_identity_provider)) {
    args$workload_identity_provider <- conn$workload_identity_provider
  }

  # Pass non-ODBC fields for snowflake_args() to use.
  if (!is.null(conn$account) && nzchar(conn$account)) {
    args$.account <- conn$account
  }
  if (!is.null(conn$host) && nzchar(conn$host)) {
    args$.host <- conn$host
  }

  args
}
