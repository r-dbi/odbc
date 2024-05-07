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
#' @param uid,pwd Manually specify a username and password for authentication.
#'   Specifying these options will disable ambient credential discovery.
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
  new("Snowflake")
}

#' @rdname snowflake
#' @export
setMethod(
  "dbConnect", "Snowflake",
  function(drv,
           account = Sys.getenv("SNOWFLAKE_ACCOUNT"),
           driver = NULL,
           warehouse = NULL,
           database = NULL,
           schema = NULL,
           uid = NULL,
           pwd = NULL,
           ...) {
    call <- caller_env()
    check_string(account, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(warehouse, allow_null = TRUE, call = call)
    check_string(database, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)
    args <- snowflake_args(
      account = account,
      driver = driver,
      warehouse = warehouse,
      database = database,
      schema = schema,
      uid = uid,
      pwd = pwd,
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
    # Connections to Snowflake are always over HTTPS.
    port = 443
  )
  auth <- snowflake_auth_args(account, ...)
  all <- utils::modifyList(c(args, auth), list(...))

  # Respect the Snowflake Partner environment variable, if present.
  if (is.null(all$application) && nchar(Sys.getenv("SF_PARTNER")) != 0) {
    all$application <- Sys.getenv("SF_PARTNER")
  }

  arg_names <- tolower(names(all))
  if (!"authenticator" %in% arg_names && !all(c("uid", "pwd") %in% arg_names)) {
    abort(
      c(
        "x" = "Failed to detect ambient Snowflake credentials.",
        "i" = "Supply `uid` and `pwd` to authenticate manually."
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

snowflake_auth_args <- function(account,
                                uid = NULL,
                                pwd = NULL,
                                authenticator = NULL,
                                ...) {
  if (!is.null(uid) && !is.null(pwd)) {
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
