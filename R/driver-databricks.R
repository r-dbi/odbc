#' @include dbi-connection.R
#' @include dbi-driver.R
NULL


#' Helper for Connecting to Databricks via ODBC
#'
#' @description
#'
#' Connect to Databricks clusters and SQL warehouses via the [Databricks ODBC
#' driver](https://www.databricks.com/spark/odbc-drivers-download).
#'
#' In particular, the custom `dbConnect()` method for the Databricks ODBC driver
#' implements a variant of Databricks's [unified authentication](https://docs.databricks.com/aws/en/dev-tools/auth/unified-auth)
#' model when no `uid` or `pwd` is supplied, checking for ambient credentials in
#' the following order:
#'
#' * Viewer-based or service principal credentials supplied by Posit Connect
#'   (requires the \pkg{connectcreds} package).
#' * Personal access tokens.
#' * Workload identity federation.
#' * OAuth machine-to-machine credentials.
#' * OAuth user-to-machine credentials suplied via Posit Workbench or the
#'   Databricks CLI on desktop.
#'
#' This aims to provide broad compatibility between \pkg{odbc} and the standard
#' environment variables used by Databricks SDKs in R and other languages.
#'
#' In addition, on macOS platforms, the `dbConnect()` method will check
#' for irregularities with how the driver is configured,
#' and attempt to fix in-situ, unless the `odbc.no_config_override`
#' environment variable is set.
#'
#' @param drv an object that inherits from [DBI::DBIDriver-class],
#' or an existing [DBI::DBIConnection-class]
#' object (in order to clone an existing connection).
#' @param httpPath,HTTPPath To query a cluster, use the HTTP Path value found
#'   under `Advanced Options > JDBC/ODBC` in the Databricks UI. For SQL
#'   warehouses, this is found under `Connection Details` instead.
#' @param useNativeQuery Suppress the driver's conversion from ANSI SQL 92 to
#'   HiveSQL.  When set to true, we also set the following related flags:
#'   `EnableNativeParameterizedQuery`, and `PopulateParametersForNativeQuery`.
#'   The default (`TRUE`), gives greater performance but could cause issues
#'   with paramterised queries (and hence `dbWriteTable()`).
#' @param workspace The URL of a Databricks workspace, e.g.
#'   `"https://example.cloud.databricks.com"`.
#' @param driver The name of the Databricks ODBC driver, or `NULL` to use the
#'   default name.
#' @param uid,pwd Manually specify a username and password for authentication.
#'   Specifying these options will disable automated credential discovery.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Databricks
#'   cluster or SQL warehouse.
#'
#' @examples
#' \dontrun{
#' DBI::dbConnect(
#'   odbc::databricks(),
#'   httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
#' )
#'
#' # Use credentials from the viewer or a service principal (when possible) in
#' # a Shiny app deployed to Posit Connect.
#' library(connectcreds)
#' server <- function(input, output, session) {
#'   conn <- DBI::dbConnect(
#'     odbc::databricks(),
#'     workspace = "https://example.cloud.databricks.com",
#'     httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
#'   )
#' }
#' }
#' @export
databricks <- function() {
  new("DatabricksOdbcDriver")
}

#' @rdname databricks
#' @export
setClass("DatabricksOdbcDriver", contains = "OdbcDriver")

#' @rdname databricks
#' @export
setMethod("dbConnect", "DatabricksOdbcDriver",
  function(drv,
           httpPath,
           workspace = Sys.getenv("DATABRICKS_HOST"),
           useNativeQuery = TRUE,
           driver = NULL,
           HTTPPath,
           uid = NULL,
           pwd = NULL,
           ...) {
    call <- caller_env()
    # For backward compatibility with RStudio connection string
    http_path <- check_exclusive(httpPath, HTTPPath, .call = call)
    check_string(get(http_path), allow_null = TRUE, arg = http_path, call = call)
    check_string(workspace, allow_null = TRUE, call = call)
    check_bool(useNativeQuery, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)

    args <- databricks_args(
      httpPath = if (missing(httpPath)) HTTPPath else httpPath,
      workspace = workspace,
      useNativeQuery = useNativeQuery,
      driver = driver,
      uid = uid,
      pwd = pwd,
      ...
    )
    # Perform some sanity checks on MacOS
    configure_simba(spark_simba_config(args$driver),
      action = "modify")
    inject(dbConnect(odbc(), !!!args))
  }
)

databricks_args <- function(httpPath,
                            workspace = Sys.getenv("DATABRICKS_HOST"),
                            useNativeQuery = FALSE,
                            driver = NULL,
                            uid = NULL,
                            pwd = NULL,
                            ...) {
  host <- databricks_host(workspace)

  args <- databricks_default_args(
    driver = driver,
    host = host,
    httpPath = httpPath,
    useNativeQuery = useNativeQuery
  )

  auth <- databricks_auth_args(host, uid = uid, pwd = pwd)
  all <- utils::modifyList(c(args, auth), list(...))

  arg_names <- tolower(names(all))
  if (!"authmech" %in% arg_names && !all(c("uid", "pwd") %in% arg_names)) {
    msg <- c(
      "Failed to detect ambient Databricks credentials.",
      "i" = "Supply {.arg uid} and {.arg pwd} to authenticate manually."
    )
    if (running_on_connect()) {
      msg <- c(
        msg,
        "i" = "Or consider enabling Posit Connect's Databricks integration. \
              For viewer-based credentials, see {.url \
              https://docs.posit.co/connect/user/oauth-integrations/#viewer-oauth-integrations}
              for details. \
              For service principal credentials, see {.url \
              https://docs.posit.co/connect/user/oauth-integrations/#service-account-oauth-integrations}
              for details."
      )
    }
    cli::cli_abort(msg, call = quote(DBI::dbConnect()))
  }

  all
}

databricks_default_args <- function(driver, host, httpPath, useNativeQuery) {
  ret <- list(
    driver = driver %||% databricks_default_driver(),
    host = host,
    httpPath = httpPath,
    thriftTransport = 2,
    userAgentEntry = databricks_user_agent(),
    # Connections to Databricks are always over HTTPS.
    port = 443,
    protocol = "https",
    ssl = 1
  )

  nativeQueryArgs <- list(useNativeQuery = as.integer(useNativeQuery))
  if (useNativeQuery) {
    # Per driver documentation, when native query is enabled, the additional two flags help
    # with properly handling parametrized queries
    nativeQueryArgs <- c(nativeQueryArgs, EnableNativeParameterizedQuery = 1, PopulateParametersForNativeQuery = 1)
  }

  ret <- c(ret, nativeQueryArgs)
  ret
}



# Returns a sensible driver name even if odbc.ini and odbcinst.ini do not
# contain an entry for the Databricks ODBC driver. For Linux and macOS we
# default to known shared library paths used by the official installers.
# On Windows we use the official driver name.
databricks_default_driver <- function() {
  find_default_driver(
    databricks_default_driver_paths(),
    fallbacks = c("Databricks", "Simba Spark ODBC Driver"),
    label = "Databricks/Spark",
    call = quote(DBI::dbConnect())
  )
}

databricks_default_driver_paths <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    paths <- Sys.glob(c(
      "/opt/rstudio-drivers/spark/bin/lib/libsparkodbc_sb*.so",
      "/opt/simba/spark/lib/64/libsparkodbc_sb*.so"
    ))
  } else if (Sys.info()["sysname"] == "Darwin") {
    paths <- Sys.glob(c(
      "/Library/simba/spark/lib/libsparkodbc_sb*.dylib",
      "/Library/databricks/databricksodbc/lib/libdatabricks*.dylib"
    ))
  } else {
    paths <- character()
  }
  paths
}

databricks_host <- function(workspace) {
  if (nchar(workspace) == 0) {
    abort(
      c(
        "No Databricks workspace URL provided.",
        i = "Either supply `workspace` argument or set env var `DATABRICKS_HOST`."
      ),
      call = quote(DBI::dbConnect())
    )
  }
  gsub("https://|/$", "", workspace)
}

#' @importFrom utils packageVersion
databricks_user_agent <- function() {
  user_agent <- paste0("r-odbc/", packageVersion("odbc"))
  if (nchar(Sys.getenv("SPARK_CONNECT_USER_AGENT")) != 0) {
    # Respect the existing user-agent if present. Normally we'd append, but the
    # Databricks ODBC driver does not yet support space-separated entries in
    # this field.
    user_agent <- Sys.getenv("SPARK_CONNECT_USER_AGENT")
  }
  user_agent
}

databricks_auth_args <- function(host, uid = NULL, pwd = NULL) {
  # Detect viewer-based credentials from Posit Connect.
  workspace <- paste0("https://", host)
  if (is_installed("connectcreds") && connectcreds::has_viewer_token(workspace)) {
    token <- connectcreds::connect_viewer_token(workspace)
    return(list(
      authMech = 11,
      auth_flow = 0,
      auth_accesstoken = token$access_token
    ))
  }

  if (is_installed("connectcreds") && connectcreds::has_service_account_token(workspace)) {
    token <- connectcreds::connect_service_account_token(workspace)
    return(list(
      authMech = 11,
      auth_flow = 0,
      auth_accesstoken = token$access_token
    ))
  }

  if (!is.null(uid) && !is.null(pwd)) {
    return(list(uid = uid, pwd = pwd, authMech = 3))
  } else if (xor(is.null(uid), is.null(pwd))) {
    abort(
      c(
        "Both `uid` and `pwd` must be specified for manual authentication.",
        i = "Or leave both unset for automated authentication."
      ),
      call = quote(DBI::dbConnect())
    )
  }

  # Check some standard Databricks environment variables. This is used to
  # implement a subset of the "Databricks client unified authentication" model.
  token <- Sys.getenv("DATABRICKS_TOKEN")
  auth_type <- Sys.getenv("DATABRICKS_AUTH_TYPE")
  client_id <- Sys.getenv("DATABRICKS_CLIENT_ID")
  client_secret <- Sys.getenv("DATABRICKS_CLIENT_SECRET")
  cli_path <- Sys.getenv("DATABRICKS_CLI_PATH", "databricks")
  cfg_file <- Sys.getenv("DATABRICKS_CONFIG_FILE")

  # Check for Workbench-provided credentials.
  wb_token <- NULL
  if (grepl("posit-workbench", cfg_file, fixed = TRUE)) {
    wb_token <- workbench_databricks_token(host, cfg_file)
  }

  if (nchar(token) != 0) {
    # An explicit PAT takes precedence over everything else.
    list(
      authMech = 3,
      uid = "token",
      pwd = token
    )
  } else if (auth_type %in% c("env-oidc", "file-oidc")) {
    # Next up is workload identity federation.
    if (nchar(client_id) == 0) {
      cli::cli_abort(
        c(
          "Workload identity federation requires a service principal.",
          "i" = "Set the {.envvar DATABRICKS_CLIENT_ID} environment variable to
                 the service principal's UUID."
        ),
        call = quote(DBI::dbConnect())
      )
    }
    id_token <- databricks_read_id_token(auth_type)
    access_token <- databricks_token_exchange(host, id_token, client_id)
    list(
      authMech = 11,
      auth_flow = 0,
      auth_accesstoken = access_token
    )
  } else if (nchar(client_id) != 0) {
    # Next up are explicit OAuth2 M2M credentials.
    list(
      authMech = 11,
      auth_flow = 1,
      auth_client_id = client_id,
      auth_client_secret = client_secret
    )
  } else if (!is.null(wb_token)) {
    # Next up are Workbench-provided credentials.
    list(
      authMech = 11,
      auth_flow = 0,
      auth_accesstoken = wb_token
    )
  } else if (!is_hosted_session() && nchar(Sys.which(cli_path)) != 0) {
    # When on desktop, try using the Databricks CLI for auth.
    output <- suppressWarnings(
      system2(
        cli_path,
        c("auth", "token", "--host", host),
        stdout = TRUE,
        stderr = TRUE
      )
    )
    output <- paste(output, collapse = "\n")
    # If we don't get an error message, try to extract the token from the JSON-
    # formatted output.
    if (grepl("access_token", output, fixed = TRUE)) {
      token <- gsub(".*access_token\":\\s?\"([^\"]+).*", "\\1", output)
      list(
        authMech = 11,
        auth_flow = 0,
        auth_accesstoken = token
      )
    }
  }
}

databricks_read_id_token <- function(auth_type) {
  if (auth_type == "env-oidc") {
    token_env_name <- Sys.getenv("DATABRICKS_OIDC_TOKEN_ENV")
    if (nchar(token_env_name) == 0) {
      token_env_name <- "DATABRICKS_OIDC_TOKEN"
    }
    token <- Sys.getenv(token_env_name)
    if (nchar(token) == 0) {
      cli::cli_abort(
        c(
          "Workload identity federation is enabled
           ({.code DATABRICKS_AUTH_TYPE=env-oidc}) but no OIDC token was found.",
          "i" = "Set the {.envvar {token_env_name}} environment variable to the
                 IdP JWT."
        ),
        call = quote(DBI::dbConnect())
      )
    }
    token
  } else {
    path <- Sys.getenv("DATABRICKS_OIDC_TOKEN_FILEPATH")
    if (nchar(path) == 0) {
      cli::cli_abort(
        c(
          "Workload identity federation is enabled
           ({.code DATABRICKS_AUTH_TYPE=file-oidc}) but
           {.envvar DATABRICKS_OIDC_TOKEN_FILEPATH} is not set.",
          "i" = "Set {.envvar DATABRICKS_OIDC_TOKEN_FILEPATH} to the path of the
                 file containing the IdP JWT."
        ),
        call = quote(DBI::dbConnect())
      )
    }
    if (!file.exists(path)) {
      cli::cli_abort(
        c(
          "OIDC token file {.file {path}} does not exist.",
          "i" = "Verify {.envvar DATABRICKS_OIDC_TOKEN_FILEPATH} points to a
                 readable file."
        ),
        call = quote(DBI::dbConnect())
      )
    }
    token <- trimws(paste(readLines(path, warn = FALSE), collapse = ""))
    if (nchar(token) == 0) {
      cli::cli_abort(
        "OIDC token file {.file {path}} is empty.",
        call = quote(DBI::dbConnect())
      )
    }
    token
  }
}

databricks_token_exchange <- function(host, id_token, client_id) {
  check_installed("httr2", "for Databricks workload identity federation")

  url <- paste0("https://", host, "/oidc/v1/token")
  body <- list(
    grant_type = "urn:ietf:params:oauth:grant-type:token-exchange",
    subject_token_type = "urn:ietf:params:oauth:token-type:jwt",
    subject_token = id_token,
    scope = "all-apis",
    client_id = client_id
  )

  req <- httr2::request(url)
  req <- httr2::req_body_form(req, !!!body)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)

  resp <- try_fetch(
    httr2::req_perform(req),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "Failed to reach the Databricks OIDC token endpoint at {.url {url}}.",
          "i" = "Check network connectivity and that {.arg workspace} is correct."
        ),
        parent = cnd,
        call = quote(DBI::dbConnect())
      )
    }
  )

  if (httr2::resp_is_error(resp)) {
    status <- httr2::resp_status(resp)
    resp_body <- tryCatch(
      httr2::resp_body_string(resp),
      error = function(e) "(unreadable)"
    )
    cli::cli_abort(
      c(
        "Databricks OIDC token exchange failed with HTTP {status}.",
        "i" = "Response: {resp_body}"
      ),
      call = quote(DBI::dbConnect())
    )
  }

  parsed <- httr2::resp_body_json(resp)
  access_token <- parsed$access_token
  if (is.null(access_token) || !nzchar(access_token)) {
    cli::cli_abort(
      c(
        "Databricks OIDC token exchange response did not contain an access
         token.",
        "i" = "Verify the federation policy is configured correctly in
               Databricks."
      ),
      call = quote(DBI::dbConnect())
    )
  }
  access_token
}

# Try to determine whether we can redirect the user's browser to a server on
# localhost, which isn't possible if we are running on a hosted platform.
#
# This is based on the strategy pioneered by the {gargle} package and {httr2}.
is_hosted_session <- function() {
  # If RStudio Server or Posit Workbench is running locally (which is possible,
  # though unusual), it's not acting as a hosted environment.
  Sys.getenv("RSTUDIO_PROGRAM_MODE") == "server" &&
    !grepl("localhost", Sys.getenv("RSTUDIO_HTTP_REFERER"), fixed = TRUE)
}


is_camel_case <- function(x) {
  grepl("^[a-z]+([A-Z_][a-z]+)*$", x)
}

dot_names <- function(...) names(substitute(...()))

# Reads Posit Workbench-managed Databricks credentials from a
# $DATABRICKS_CONFIG_FILE. The generated file will look as follows:
#
# [workbench]
# host = some-host
# token = some-token
workbench_databricks_token <- function(host, cfg_file) {
  cfg <- readLines(cfg_file)
  # We don't attempt a full parse of the INI syntax supported by Databricks
  # config files, instead relying on the fact that this particular file will
  # always contain only one section.
  if (!any(grepl(host, cfg, fixed = TRUE))) {
    # The configuration doesn't actually apply to this host.
    return(NULL)
  }
  line <- grepl("token = ", cfg, fixed = TRUE)
  token <- gsub("token = ", "", cfg[line])
  if (nchar(token) == 0) {
    return(NULL)
  }
  token
}

# p. 44 https://downloads.datastax.com/odbc/2.6.5.1005/Simba%20Spark%20ODBC%20Install%20and%20Configuration%20Guide.pdf
spark_simba_config <- function(driver) {
  spark_env <- Sys.getenv("SIMBASPARKINI")
  URL <- "https://www.databricks.com/spark/odbc-drivers-download"
  if (!identical(spark_env, "")) {
    return(list(path = spark_env, url = URL))
  }
  # Attempt first the exact driver directory
  res <- list.files(
    driver_dir(driver),
    pattern = "simba\\.sparkodbc\\.ini$|databricks\\.databricksodbc\\.ini$",
    full.names = TRUE
  )
  if (!length(res)) {
    common_dirs <- unique(c(
      "/Library/simba/spark/lib",
      "/Library/databricks/databricksodbc/lib",
      "/etc",
      getwd(),
      Sys.getenv("HOME")
    ))
    res <- list.files(
      common_dirs,
      pattern = "simba\\.sparkodbc\\.ini$|databricks\\.databricksodbc\\.ini$",
      full.names = TRUE
    )
  }
  return(list(path = res, url = URL))
}
