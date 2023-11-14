#' Helper for Connecting to Databricks via ODBC
#'
#' @description
#'
#' Connect to Databricks clusters and SQL warehouses via the [Databricks ODBC
#' driver](https://www.databricks.com/spark/odbc-drivers-download).
#'
#' In particular, the custom `dbConnect()` method for the Databricks ODBC driver
#' implements a subset of the [Databricks client unified authentication](https://docs.databricks.com/en/dev-tools/auth.html#databricks-client-unified-authentication)
#' model, with support for personal access tokens, OAuth machine-to-machine
#' credentials, and OAuth user-to-machine credentials supplied via Posit
#' Workbench or the Databricks CLI on desktop.
#'
#' All of these credentials are detected automatically if present using
#' [standard environment variables](https://docs.databricks.com/en/dev-tools/auth.html#environment-variables-and-fields-for-client-unified-authentication).
#'
#' @inheritParams DBI::dbConnect
#' @param http_path To query a cluster, use the HTTP Path value found under
#'   `Advanced Options > JDBC/ODBC` in the Databricks UI. For SQL warehouses,
#'   this is found under `Connection Details` instead.
#' @param workspace The URL of a Databricks workspace, e.g.
#'   `"https://example.cloud.databricks.com"`.
#' @param driver The name of the Databricks ODBC driver, or `NULL` to use the
#'   default name.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Databricks
#'   cluster or SQL warehouse.
#'
#' @examples
#' \dontrun{
#' DBI::dbConnect(
#'   odbc::databricks(),
#'   http_path = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
#' )
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
setMethod(
  "dbConnect", "DatabricksOdbcDriver",
  function(drv, http_path, workspace = Sys.getenv("DATABRICKS_HOST"),
           driver = NULL, ...) {
    args <- databricks_args(
      http_path = http_path,
      workspace = workspace,
      driver = driver
    )
    args <- c(args, ...)
    inject(dbConnect(odbc(), !!!args))
  }
)

databricks_args <- function(http_path,
                            workspace = Sys.getenv("DATABRICKS_HOST"),
                            driver = NULL) {
  if (nchar(workspace) == 0) {
    stop("No Databricks workspace URL provided")
  }
  hostname <- gsub("https://", "", workspace)
  driver <- driver %||% default_databricks_driver()

  # Check some standard Databricks environment variables. This is used to
  # implement a subset of the "Databricks client unified authentication" model.
  token <- Sys.getenv("DATABRICKS_TOKEN")
  client_id <- Sys.getenv("DATABRICKS_CLIENT_ID")
  client_secret <- Sys.getenv("DATABRICKS_CLIENT_SECRET")
  cli_path <- Sys.getenv("DATABRICKS_CLI_PATH", "databricks")

  user_agent <- paste0("r-odbc/", utils::packageVersion("odbc"))
  if (nchar(Sys.getenv("SPARK_CONNECT_USER_AGENT")) != 0) {
    # Respect the existing user-agent if present. Normally we'd append, but the
    # Databricks ODBC driver does not yet support space-separated entries in
    # this field.
    user_agent <- Sys.getenv("SPARK_CONNECT_USER_AGENT")
  }

  args <- list(
    driver = driver,
    Host = hostname,
    HTTPPath = http_path,
    ThriftTransport = 2,
    UserAgentEntry = user_agent,
    # Connections to Databricks are always over HTTPS.
    Port = 443,
    Protocol = "https",
    SSL = 1
  )

  # Check for Workbench-provided credentials.
  wb_token <- NULL
  if (exists(".rs.api.getDatabricksToken")) {
    getDatabricksToken <- get(".rs.api.getDatabricksToken")
    wb_token <- getDatabricksToken(workspace)
  }

  if (nchar(token) != 0) {
    # An explicit PAT takes precedence over everything else.
    args <- c(args, AuthMech = 3, uid = "token", pwd = token)
  } else if (nchar(client_id) != 0) {
    # Next up are explicit OAuth2 M2M credentials.
    args <- c(
      args,
      AuthMech = 11,
      Auth_Flow = 1,
      Auth_Client_ID = client_id,
      Auth_Client_Secret = client_secret
    )
  } else if (!is.null(wb_token)) {
    # Next up are Workbench-provided credentials.
    args <- c(args, AuthMech = 11, Auth_Flow = 0, Auth_AccessToken = wb_token)
  } else if (!is_hosted_session() && nchar(Sys.which(cli_path)) != 0) {
    # When on desktop, try using the Databricks CLI for auth.
    output <- suppressWarnings(
      system2(
        cli_path,
        c("auth", "token", "--host", workspace),
        stdout = TRUE,
        stderr = TRUE
      )
    )
    output <- paste(output, collapse = "\n")
    # If we don't get an error message, try to extract the token from the JSON-
    # formatted output.
    if (grepl("access_token", output, fixed = TRUE)) {
      token <- gsub(".*access_token\":\\s?\"([^\"]+).*", "\\1", output)
      args <- c(args, AuthMech = 11, Auth_Flow = 0, Auth_AccessToken = token)
    }
  }

  args
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

# Returns a sensible driver name even if odbc.ini and odbcinst.ini do not
# contain an entry for the Databricks ODBC driver.
default_databricks_driver <- function() {
  # For Linux and macOS we can default to the shared library paths used by the
  # official installers. On Windows we use the official driver name instead.
  default_path <- ""
  if (Sys.info()["sysname"] == "Linux") {
    default_path <- "/opt/simba/spark/lib/64/libsparkodbc_sb64.so"
  } else if (Sys.info()["sysname"] == "Darwin") {
    default_path <- "/Library/simba/spark/lib/libsparkodbc_sbu.dylib"
  }

  if (file.exists(default_path)) default_path else "Simba Spark ODBC Driver"
}
