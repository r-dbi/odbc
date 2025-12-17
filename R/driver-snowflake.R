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
setMethod("odbcConnectionColumns_", c("Snowflake", "character"),
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
#' detects ambient OAuth credentials on platforms like Snowpark Container
#' Services or Posit Workbench. It can also detect viewer-based
#' credentials on Posit Connect if the \pkg{connectcreds} package is
#' installed.
#'
#' ## Configuration Files
#'
#' Connection parameters can be loaded from Snowflake configuration files
#' (`~/.snowflake/connections.toml` or `~/.snowflake/config.toml`), following
#' the same conventions as the Snowflake Python connector. This requires the
#' \pkg{toml} package to be installed.
#'
#' Configuration files are loaded from `SNOWFLAKE_HOME` environment variable,
#' `~/.snowflake/` if it exists, or platform-specific defaults
#' (`~/Library/Application Support/snowflake/` on macOS,
#' `~/.config/snowflake/` on Linux).
#'
#' The `SNOWFLAKE_CONNECTIONS` environment variable can contain a full TOML
#' document that overrides file-based connections. The
#' `SNOWFLAKE_DEFAULT_CONNECTION_NAME` environment variable overrides the
#' default connection name.
#'
#' On non-Windows platforms, configuration files are checked for secure
#' permissions. Files writable by group or others will cause an error; files
#' readable by others will generate a warning. Set
#' `SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE=true` to suppress
#' these checks.
#'
#' In addition, on macOS platforms, the `dbConnect` method will check and warn
#' if it detects irregularities with how the driver is configured, unless the
#' `odbc.no_config_override` environment variable is set.
#'
#' @param drv an object that inherits from [DBI::DBIDriver-class],
#' or an existing [DBI::DBIConnection-class]
#' object (in order to clone an existing connection).
#' @param connection_name The name of a connection profile to load from
#'   configuration files. If provided, connection parameters are loaded from
#'   `~/.snowflake/connections.toml` (or the location specified by
#'   `SNOWFLAKE_HOME`) and merged with any explicitly provided arguments.
#'   Requires the \pkg{toml} package.
#' @param connections_file_path Optional custom path to a `connections.toml`
#'   file. If `NULL`, uses the default location within `SNOWFLAKE_HOME`.
#' @param account A Snowflake [account
#'   identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier),
#'   e.g. `"testorg-test_account"`. If not provided and no `connection_name`
#'   is specified, the `SNOWFLAKE_ACCOUNT` environment variable will be used.
#' @param driver The name of the Snowflake ODBC driver, or `NULL` to use the
#'   default name.
#' @param warehouse The name of a Snowflake compute warehouse, or `NULL` to use
#'   the default.
#' @param database The name of a Snowflake database, or `NULL` to use the
#'   default.
#' @param schema The name of a Snowflake database schema, or `NULL` to use the
#'   default.
#' @param uid,pwd Manually specify a username and password for authentication.
#'   Specifying these options will disable ambient credential discovery and
#'   config file loading (unless `connection_name` is also specified).
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
#' # Load connection from config file (~/.snowflake/connections.toml)
#' # Requires the toml package to be installed.
#' DBI::dbConnect(odbc::snowflake(), connection_name = "prod")
#'
#' # Load connection and override specific parameters
#' DBI::dbConnect(
#'   odbc::snowflake(),
#'   connection_name = "prod",
#'   warehouse = "ADHOC_WH"
#' )
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
           connection_name = NULL,
           connections_file_path = NULL,
           account = NULL,
           driver = NULL,
           warehouse = NULL,
           database = NULL,
           schema = NULL,
           uid = NULL,
           pwd = NULL,
           ...) {
    call <- caller_env()
    check_string(connection_name, allow_null = TRUE, call = call)
    check_string(connections_file_path, allow_null = TRUE, call = call)
    check_string(account, allow_null = TRUE, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(warehouse, allow_null = TRUE, call = call)
    check_string(database, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)
    args <- snowflake_args(
      connection_name = connection_name,
      connections_file_path = connections_file_path,
      account = account,
      driver = driver,
      warehouse = warehouse,
      database = database,
      schema = schema,
      uid = uid,
      pwd = pwd,
      ...
    )
    # Perform some sanity checks on MacOS
    configure_simba(snowflake_simba_config(args$driver),
      action = "modify")
    inject(dbConnect(odbc(), !!!args))
  }
)

# Build connection arguments for Snowflake ODBC connections
#
# This function resolves and merges connection parameters from three sources
# (in order of precedence, highest to lowest):
# 1. Programmatic arguments passed directly to dbConnect()
# 2. Connection parameters from Snowflake config files (connections.toml)
# 3. Environment variables (SNOWFLAKE_ACCOUNT, only in programmatic mode)
#
# The function handles three connection resolution cases:
# - Case 1: Named connection (connection_name specified) - loads from config,
#   merges with programmatic args
# - Case 2: Default connection (no programmatic params) - loads "default"
#   connection from config, or uses default_connection_name from config.toml
# - Case 3: Programmatic only (programmatic params provided, no connection_name) -
#   skips config files entirely
#
# Authentication is delegated to snowflake_auth_args(), which handles various
# auth methods including uid/pwd, externalbrowser, SNOWFLAKE_JWT, OAuth tokens
# from Posit Connect, and Workbench-managed credentials.
#
# @param connection_name Name of connection to load from connections.toml
# @param connections_file_path Optional path to connections.toml file
# @param account Snowflake account identifier
# @param driver ODBC driver name or path
# @param warehouse Snowflake warehouse name
# @param database Snowflake database name
# @param schema Snowflake schema name
# @param uid User ID for authentication
# @param pwd Password for authentication
# @param ... Additional connection parameters
# @return Named list of connection arguments suitable for dbConnect(odbc(), ...)
# @noRd
snowflake_args <- function(connection_name = NULL,
                           connections_file_path = NULL,
                           account = NULL,
                           driver = NULL,
                           warehouse = NULL,
                           database = NULL,
                           schema = NULL,
                           uid = NULL,
                           pwd = NULL,
                           ...) {
  # Check for Workbench mode early - skip config loading if SNOWFLAKE_HOME
  # contains "posit-workbench" (Workbench handles credentials differently)
  sf_home <- Sys.getenv("SNOWFLAKE_HOME")
  is_workbench_mode <- grepl("posit-workbench", sf_home, fixed = TRUE)

  # 1. Collect programmatic parameters (only non-NULL values)
  programmatic_params <- list()
  if (!is.null(account)) programmatic_params$account <- account
  if (!is.null(warehouse)) programmatic_params$warehouse <- warehouse
  if (!is.null(database)) programmatic_params$database <- database
  if (!is.null(schema)) programmatic_params$schema <- schema
  if (!is.null(uid)) programmatic_params$uid <- uid
  if (!is.null(pwd)) programmatic_params$pwd <- pwd

  # Add any additional params from ...
  dots <- list(...)
  programmatic_params <- c(programmatic_params, dots)

  # 2. Resolve connection parameters (handles all 3 cases)
  # Skip config file loading in Workbench mode (Workbench handles credentials separately)
  if (is_workbench_mode && is.null(connection_name)) {
    # Treat Workbench mode like programmatic mode (skip config loading)
    resolved <- list(params = programmatic_params, mode = "programmatic")
  } else {
    resolved <- resolve_connection_params(
      connection_name = connection_name,
      connections_file_path = connections_file_path,
      programmatic_params = programmatic_params
    )
  }
  resolved_params <- resolved$params
  is_programmatic_mode <- resolved$mode == "programmatic"

  # 3. Apply SNOWFLAKE_ACCOUNT env var only in Case 3 (programmatic mode)
  if (is_programmatic_mode) {
    resolved_params$account <- resolved_params$account %||%
      Sys.getenv("SNOWFLAKE_ACCOUNT", unset = NA_character_)
    if (is.na(resolved_params$account)) {
      resolved_params$account <- NULL
    }
  }

  # 4. Extract key values with fallbacks
  account <- resolved_params$account
  driver <- driver %||% resolved_params$driver %||% snowflake_default_driver()

  # 5. Build base args
  args <- list(
    driver = driver,
    account = account,
    server = snowflake_server(account),
    # Connections to Snowflake are always over HTTPS.
    port = 443
  )

  # 6. Merge resolved params into args
  args <- utils::modifyList(args, resolved_params)

  # 7. Get authentication args
  # Filter out params that are already handled to avoid "matched by multiple actual arguments"
  dots_filtered <- list(...)
  dots_filtered$uid <- NULL
  dots_filtered$pwd <- NULL
  dots_filtered$authenticator <- NULL

  auth <- do.call(
    snowflake_auth_args,
    c(
      list(
        account = account,
        uid = resolved_params$uid,
        pwd = resolved_params$pwd,
        authenticator = resolved_params$authenticator
      ),
      dots_filtered
    )
  )

  # 8. Merge auth into args, then apply final programmatic overrides
  # Remove uid/pwd/authenticator from args before merging with auth to avoid duplicates
  # (auth may return these, and args already has them from resolved_params)
  args$uid <- NULL
  args$pwd <- NULL
  args$authenticator <- NULL
  all <- utils::modifyList(utils::modifyList(args, auth), list(...))

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

snowflake_auth_args <- function(account,
                                uid = NULL,
                                pwd = NULL,
                                authenticator = NULL,
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
    return(list(uid = uid, pwd = pwd, authenticator = authenticator))
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

  # Check for Workbench-provided credentials.
  sf_home <- Sys.getenv("SNOWFLAKE_HOME")
  if (grepl("posit-workbench", sf_home, fixed = TRUE)) {
    token <- workbench_snowflake_token(account, sf_home)
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

# Reads Posit Workbench-managed Snowflake credentials from a
# $SNOWFLAKE_HOME/connections.toml file, as used by the Snowflake Connector for
# Python implementation. The file will look as follows:
#
# [workbench]
# account = "account-id"
# token = "token"
# authenticator = "oauth"
workbench_snowflake_token <- function(account, sf_home) {
  cfg <- readLines(file.path(sf_home, "connections.toml"))
  # We don't attempt a full parse of the TOML syntax, instead relying on the
  # fact that this file will always contain only one section.
  if (!any(grepl(account, cfg, fixed = TRUE))) {
    # The configuration doesn't actually apply to this account.
    return(NULL)
  }
  line <- grepl("token = ", cfg, fixed = TRUE)
  token <- gsub("token = ", "", cfg[line])
  if (nchar(token) == 0) {
    return(NULL)
  }
  # Drop enclosing quotes.
  gsub("\"", "", token)
}

# --- Snowflake Configuration File Support ---
# These functions implement loading connection parameters from TOML config files
# following the Python Snowflake connector behavior.

#' Get the Snowflake configuration directory path
#'
#' Resolves the configuration directory with the following precedence:
#' 1. SNOWFLAKE_HOME environment variable (with ~ expansion)
#' 2. ~/.snowflake/ if it exists
#' 3. Platform-specific defaults
#'
#' @return Character string path to config directory
#' @noRd
snowflake_config_dir <- function() {
  # 1. Check SNOWFLAKE_HOME env var with ~ expansion
  snowflake_home <- Sys.getenv("SNOWFLAKE_HOME", "")
  if (nchar(snowflake_home) > 0) {
    return(path.expand(snowflake_home))
  }

  # 2. Check if ~/.snowflake/ exists
  default_path <- path.expand("~/.snowflake")
  if (dir.exists(default_path)) {
    return(default_path)

  }

  # 3. Platform-specific fallback
  if (is_windows()) {
    # Windows: %LOCALAPPDATA%/snowflake/
    return(file.path(Sys.getenv("LOCALAPPDATA"), "snowflake"))
  } else if (Sys.info()["sysname"] == "Darwin") {
    # macOS: ~/Library/Application Support/snowflake/
    return(path.expand("~/Library/Application Support/snowflake"))
  } else {
    # Linux: respect XDG_CONFIG_HOME or default to ~/.config/snowflake/
    xdg_config <- Sys.getenv("XDG_CONFIG_HOME", "")
    if (nchar(xdg_config) > 0) {
      return(file.path(xdg_config, "snowflake"))
    } else {
      return(path.expand("~/.config/snowflake"))
    }
  }
}

#' Check file permissions for security (non-Windows only)
#'
#' @param file_path Path to TOML config file
#' @return NULL invisibly; throws error or warning on bad permissions
#' @noRd
check_toml_file_permissions <- function(file_path) {
  # Skip on Windows
  if (is_windows()) {
    return(invisible())
  }

  # Check env var bypass
  if (nchar(Sys.getenv("SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE")) > 0) {
    return(invisible())
  }

  # Get file info
  file_info <- file.info(file_path)
  mode <- file_info$mode

  if (is.na(mode)) {
    return(invisible())
  }

  # Convert mode to integer for bit manipulation
  # mode is an "octmode" object, need explicit conversion
  mode_int <- as.integer(mode)

  # Check permission bits:
  # Group write = 020 (octal) = 16 (decimal)
  # Other write = 002 (octal) = 2 (decimal)
  # Other read = 004 (octal) = 4 (decimal)

  # Check if writable by group (bit for group write)
  group_write <- bitwAnd(mode_int, 16L) > 0  # 020 octal = 16 decimal
  # Check if writable by others (bit for other write)
  other_write <- bitwAnd(mode_int, 2L) > 0   # 002 octal = 2 decimal
  # Check if readable by others (bit for other read)
  other_read <- bitwAnd(mode_int, 4L) > 0    # 004 octal = 4 decimal

  # ERROR if writable by group or others
  if (group_write || other_write) {
    perms <- format(as.octmode(mode), width = 3)
    abort(
      c(
        sprintf("file '%s' is writable by group or others \u2014 this poses a security", file_path),
        "!" = "risk because it allows unauthorized users to modify sensitive settings.",
        "i" = sprintf("Your Permission: %s", perms),
        "i" = sprintf("To restrict permissions, run `chmod 0600 \"%s\"`.", file_path)
      ),
      call = quote(DBI::dbConnect())
    )
  }

  # WARNING if readable by others
  if (other_read) {
    cli::cli_warn(c(
      sprintf("Bad owner or permissions on %s.", file_path),
      "i" = sprintf("To change owner, run `chown $USER \"%s\"`.", file_path),
      "i" = sprintf("To restrict permissions, run `chmod 0600 \"%s\"`.", file_path),
      "i" = "To skip this warning, set environment variable",
      " " = "SF_SKIP_WARNING_FOR_READ_PERMISSIONS_ON_CONFIG_FILE=true."
    ))
  }

  invisible()
}

#' Parse a TOML file with proper error handling
#'
#' @param file_path Path to TOML file
#' @return Named list with parsed TOML content
#' @noRd
parse_toml_file <- function(file_path) {
  check_toml_installed()

  tryCatch(
    toml::read_toml(file_path),
    error = function(e) {
      abort(
        sprintf("An unknown error happened while loading '%s'", file_path),
        parent = e,
        call = quote(DBI::dbConnect())
      )
    }
  )
}

#' Parse a TOML string (from env var) with proper error handling
#'
#' @param toml_string TOML content as a string
#' @return Named list with parsed TOML content
#' @noRd
parse_toml_string <- function(toml_string) {
  check_toml_installed()

  tryCatch(
    toml::parse_toml(toml_string),
    error = function(e) {
      abort(
        "Failed to parse SNOWFLAKE_CONNECTIONS environment variable as TOML",
        parent = e,
        call = quote(DBI::dbConnect())
      )
    }
  )
}

#' Check if toml package is installed
#' @noRd
check_toml_installed <- function() {
  if (!rlang::is_installed("toml")) {
    abort(
      c(
        "The {.pkg toml} package is required to load Snowflake configuration files.",
        "i" = "Install it with: install.packages(\"toml\")"
      ),
      call = quote(DBI::dbConnect())
    )
  }
}

#' Load and merge Snowflake configuration from files and environment variables
#'
#' Uses lazy evaluation via delayedAssign to only parse TOML when needed.
#' Errors about missing toml package only occur if we actually need to parse TOML.
#'
#' @param config_dir Path to Snowflake config directory
#' @param connections_file_path Optional custom path to connections.toml
#' @return Named list with 'default_connection_name' and 'connections'
#' @noRd
load_snowflake_config <- function(config_dir, connections_file_path = NULL) {
  # This function uses delayedAssign() to create lazy promises for each config
  # source (env vars, connections.toml, config.toml). Benefits of this approach:
  #
  # 1. Only parses TOML that's actually needed. If SNOWFLAKE_CONNECTIONS is set,
  #    we never read connections.toml. If both env vars are set, we skip files.
  #
  # 2. The "toml package required" error only triggers when we actually need to
  #    parse TOML. Programmatic params (Case 3) or missing config files don't
  #    require toml.
  #
  # 3. Easier to reason about than imperative code with nested conditionals.
  #    Each promise is self-contained: it checks if its source exists, handles
  #    errors, and returns NULL or a value. The precedence logic is expressed
  #    clearly at the end with %||% chains, which short-circuit evaluation.
  #    No complex state tracking or edge cases to handle.

  # Promise: toml check - errors if not installed, invisible() if installed
  delayedAssign("toml_check", {
    check_toml_installed()
    invisible()
  })

  # Promise: parsed connections.toml (or NULL if doesn't exist)
  delayedAssign("connections_toml", {
    conn_file <- connections_file_path %||% file.path(config_dir, "connections.toml")
    if (!file.exists(conn_file)) {
      NULL
    } else {
      force(toml_check)
      check_toml_file_permissions(conn_file)
      parse_toml_file(conn_file)
    }
  })

  # Promise: parsed config.toml (or NULL if doesn't exist)
  delayedAssign("config_toml", {
    config_file <- file.path(config_dir, "config.toml")
    if (!file.exists(config_file)) {
      NULL
    } else {
      force(toml_check)
      check_toml_file_permissions(config_file)
      parse_toml_file(config_file)
    }
  })

  # Promise: parsed SNOWFLAKE_CONNECTIONS env var (or NULL if not set)
  delayedAssign("env_connections", {
    val <- Sys.getenv("SNOWFLAKE_CONNECTIONS", "")
    if (nchar(val) == 0) {
      NULL
    } else {
      force(toml_check)
      parse_toml_string(val)
    }
  })

  # Promise: SNOWFLAKE_DEFAULT_CONNECTION_NAME env var (or NULL if not set)
  delayedAssign("env_default_connection_name", {
    val <- Sys.getenv("SNOWFLAKE_DEFAULT_CONNECTION_NAME", "")
    if (nchar(val) == 0) NULL else val
  })

  # Chain together with precedence rules:
  # - connections: SNOWFLAKE_CONNECTIONS > connections.toml > config.toml[connections]
  # - default_connection_name: SNOWFLAKE_DEFAULT_CONNECTION_NAME > config.toml > "default"
  list(
    default_connection_name = env_default_connection_name %||%
                              config_toml$default_connection_name %||%
                              "default",
    connections = env_connections %||%
                  connections_toml %||%
                  config_toml$connections %||%
                  list()
  )
}

#' Map Python-style parameter names to ODBC parameter names
#'
#' @param params Named list of connection parameters
#' @return Named list with mapped parameter names
#' @noRd
map_param_names <- function(params) {
  # Map Python-style names to ODBC names
  mapping <- list(
    user = "uid",
    password = "pwd"
  )

  for (old_name in names(mapping)) {
    if (!is.null(params[[old_name]])) {
      new_name <- mapping[[old_name]]
      params[[new_name]] <- params[[old_name]]
      params[[old_name]] <- NULL
    }
  }

  params
}

#' Resolve connection parameters based on the three resolution cases
#'
#' @param connection_name Optional connection name to load
#' @param connections_file_path Optional custom path to connections.toml
#' @param programmatic_params List of parameters passed programmatically
#' @return Named list with 'params' (connection parameters) and 'mode' ("config" or "programmatic")
#' @noRd
resolve_connection_params <- function(connection_name = NULL,
                                      connections_file_path = NULL,
                                      programmatic_params = list()) {
  # Determine if we have meaningful programmatic params (not including driver)
  meaningful_params <- c("account", "uid", "pwd", "authenticator", "warehouse",
                         "database", "schema", "role", "host", "port")
  has_programmatic_params <- any(names(programmatic_params) %in% meaningful_params)

  # Case 3: Only programmatic parameters (no connection_name, has meaningful params)
  if (is.null(connection_name) && has_programmatic_params) {
    # Use only programmatic params, don't load from files
    return(list(params = programmatic_params, mode = "programmatic"))
  }

  # Cases 1 & 2: Need to load configuration
  config_dir <- snowflake_config_dir()
  config <- load_snowflake_config(config_dir, connections_file_path)

  # Case 2: No connection_name, no meaningful params -> use default connection
  if (is.null(connection_name)) {
    connection_name <- config$default_connection_name

    if (!connection_name %in% names(config$connections)) {
      known_names <- names(config$connections)
      if (length(known_names) == 0) {
        abort(
          c(
            sprintf("Default connection with name '%s' cannot be found.", connection_name),
            "i" = "No connections defined in configuration files."
          ),
          call = quote(DBI::dbConnect())
        )
      } else {
        abort(
          sprintf(
            "Default connection with name '%s' cannot be found, known ones are [%s]",
            connection_name,
            paste0("'", known_names, "'", collapse = ", ")
          ),
          call = quote(DBI::dbConnect())
        )
      }
    }

    # Use default connection params, map names
    file_params <- map_param_names(config$connections[[connection_name]])
    return(list(params = file_params, mode = "config"))
  }

  # Case 1: Explicit connection_name provided
  if (!connection_name %in% names(config$connections)) {
    known_names <- names(config$connections)
    if (length(known_names) == 0) {
      abort(
        c(
          sprintf("Invalid connection_name '%s'.", connection_name),
          "i" = "No connections defined in configuration files."
        ),
        call = quote(DBI::dbConnect())
      )
    } else {
      abort(
        sprintf(
          "Invalid connection_name '%s', known ones are [%s]",
          connection_name,
          paste0("'", known_names, "'", collapse = ", ")
        ),
        call = quote(DBI::dbConnect())
      )
    }
  }

  # Merge: file params as base, programmatic params override
  file_params <- map_param_names(config$connections[[connection_name]])
  merged_params <- utils::modifyList(file_params, programmatic_params)
  list(params = merged_params, mode = "config")
}
