
# Microsoft SQL Server ---------------------------------------------------------

#' SQL Server
#'
#' Details of SQL Server methods for odbc and DBI generics.
#'
#' @rdname SQLServer
#' @export
setClass("Microsoft SQL Server", contains = "OdbcConnection")

#' @description
#' ## `dbUnquoteIdentifier()`
#'
#' `conn@quote` returns the quotation mark, but quotation marks and square
#' brackets can be used interchangeably for delimited identifiers.
#' (<https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers>).
#' This function strips the brackets first and then calls the DBI method to
#' strip the quotation marks.
#' @rdname SQLServer
#' @docType methods
#' @usage NULL
#' @keywords internal
setMethod("dbUnquoteIdentifier", c("Microsoft SQL Server", "SQL"),
  function(conn, x, ...) {
    x <- gsub("(\\[)([^\\.]+?)(\\])", "\\2", x)
    callNextMethod(conn, x, ...)
  }
)


#' @description
#' ## `isTempTable()`
#'
#' Local temp tables are stored as
#' `[tempdb].[dbo].[#name]_____[numeric identifier]`, so `isTempTable()`
#' returns `TRUE` if `catalog_name` is `"tempdb"` or `"%"`, or the
#' name starts with `"#"`.
#' @rdname SQLServer
#' @usage NULL
setMethod("isTempTable", c("Microsoft SQL Server", "character"),
  function(conn, name, catalog_name = NULL, schema_name = NULL, ...) {
    if (!is.null(catalog_name) &&
      catalog_name != "%" &&
      length(catalog_name) > 0 &&
      catalog_name != "tempdb") {
      return(FALSE)
    }

    grepl("^[#][^#]", name)
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("isTempTable", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    isTempTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)


#' @description
#' ## `dbExistsTable()`
#' The default implementation reports temporary tables as non-existent
#' since they live in a different catalog. This method provides a special
#' case for temporary tables, as identified by `isTempTable()`.
#' @rdname SQLServer
#' @docType methods
#' @usage NULL
setMethod("dbExistsTable", c("Microsoft SQL Server", "character"),
  function(conn, name, ...) {
    check_string(name)
    if (isTempTable(conn, name, ...)) {
      query <- paste0("SELECT OBJECT_ID('tempdb..", name, "')")
      !is.na(dbGetQuery(conn, query)[[1]])
    } else {
      df <- odbcConnectionTables(conn, name = name, ...)
      NROW(df) > 0
    }
  }
)

#' @description
#' ## `dbListTables()`
#' The default implementation reports temporary tables as non-existent
#' when a `catalog_name` isn't supplied since they live in a different catalog.
#' This method provides a special case for temporary tables.
#' @rdname SQLServer
#' @usage NULL
setMethod("dbListTables", "Microsoft SQL Server",
  function(conn,
           catalog_name = NULL,
           schema_name = NULL,
           table_name = NULL,
           table_type = NULL,
           ...) {
    check_string(catalog_name, allow_null = TRUE)
    check_string(schema_name, allow_null = TRUE)
    check_string(table_name, allow_null = TRUE)
    check_string(table_type, allow_null = TRUE)

    res <- callNextMethod()

    if (is.null(catalog_name) && is.null(schema_name)) {
      res_temp <- callNextMethod(
        conn = conn,
        catalog_name = "tempdb",
        schema_name = "dbo"
      )

      res <- c(res, res_temp)
    }

    res
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("dbExistsTable", c("Microsoft SQL Server", "Id"),
  function(conn, name, ...) {
    dbExistsTable(
      conn,
      name = id_field(name, "table"),
      catalog_name = id_field(name, "catalog"),
      schema_name = id_field(name, "schema")
    )
  }
)

#' @rdname SQLServer
#' @usage NULL
setMethod("dbExistsTable", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    dbExistsTable(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

#' @description
#' ## `odbcConnectionSchemas`
#'
#' Method for an internal function. Calls catalog-specific `sp_tables` to make
#' sure we list the schemas in the appropriate database/catalog.
#' @rdname SQLServer
#' @usage NULL
setMethod(
  "odbcConnectionSchemas", "Microsoft SQL Server",
  function(conn, catalog_name = NULL) {

    if (is.null(catalog_name) || !nchar(catalog_name)) {
      return(callNextMethod())
    }
    sproc <- paste(
      dbQuoteIdentifier(conn, catalog_name), "dbo.sp_tables", sep = ".")

    res <- dbGetQuery(conn, paste0(
        "EXEC ", sproc, " ",
        "@table_name = '', ",
        "@table_owner = '%', ",
        "@table_qualifier = ''"
    ))
    res$TABLE_OWNER
  }
)

#' @rdname SQLServer
#' @description
#' ## `sqlCreateTable()`
#'
#' Warns if `temporary = TRUE` but the `name` does not conform to temp table
#' naming conventions (i.e. it doesn't start with `#`).
#' @usage NULL
setMethod("sqlCreateTable", "Microsoft SQL Server",
  function(con,
           table,
           fields,
           row.names = NA,
           temporary = FALSE,
           ...,
           field.types = NULL) {
    check_bool(temporary)
    check_row.names(row.names)
    check_field.types(field.types)
    if (temporary && !isTempTable(con, table)) {
      cli::cli_warn(
        "{.arg temporary} is {.code TRUE}, but table name doesn't use # prefix."
      )
    }
    temporary <- FALSE
    callNextMethod()
  }
)

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Microsoft SQL Server",
  function(con, obj, ...) {
    switch_type(
      obj,
      factor = varchar(obj),
      datetime = "DATETIME",
      date = "DATE",
      time = "TIME",
      binary = varbinary(obj),
      integer = "INT",
      int64 = "BIGINT",
      double = "FLOAT",
      character = varchar(obj),
      logical = "BIT",
      list = varchar(obj),
      stop("Unsupported type", call. = FALSE)
    )
  }
)

#' @description
#' ## `odbcConnectionColumns_()`
#'
#' If temp table, query the database for the
#' actual table name.
#' @rdname SQLServer
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Microsoft SQL Server", "character"),
  function(conn,
           name,
           ...,
           catalog_name = NULL,
           schema_name = NULL,
           column_name = NULL,
           exact = FALSE) {
    if (exact &&
      isTempTable(conn, name, catalog_name, schema_name, column_name, exact)) {
      catalog_name <- "tempdb"
      schema_name <- "dbo"
      query <- paste0("SELECT name FROM tempdb.sys.tables WHERE ",
        "object_id = OBJECT_ID('tempdb..", name, "')")
      name <- dbGetQuery(conn, query)[[1]]
    }

    callNextMethod(
      conn = conn,
      name = name,
      ...,
      catalog_name = catalog_name,
      schema_name = schema_name,
      column_name = column_name,
      exact = exact
    )
  }
)

#' @description
#' ## `odbcConnectionColumns_()`
#'
#' Copied over from odbc-connection to avoid S4 dispatch NOTEs.
#' @rdname SQLServer
#' @usage NULL
setMethod("odbcConnectionColumns_", c("Microsoft SQL Server", "SQL"),
  function(conn, name, ...) {
    odbcConnectionColumns_(conn, dbUnquoteIdentifier(conn, name)[[1]], ...)
  }
)

#' Helper for Connecting to Azure Synapse via ODBC
#'
#' @description
#'
#' Connect to Synapse clusters and SQL warehouses via the [Synapse ODBC
#' driver](https://www.synapse.com/spark/odbc-drivers-download).
#'
#' In particular, the custom `dbConnect()` method for the Synapse ODBC driver
#' implements a subset of the [Synapse client unified authentication](https://docs.synapse.com/en/dev-tools/auth.html#synapse-client-unified-authentication)
#' model, with support for personal access tokens, OAuth machine-to-machine
#' credentials, and OAuth user-to-machine credentials supplied via Posit
#' Workbench or the Synapse CLI on desktop. It can also detect viewer-based
#' credentials on Posit Connect if the \pkg{connectcreds} package is
#' installed. All of these credentials are detected automatically if present
#' using [standard environment variables](https://docs.synapse.com/en/dev-tools/auth.html#environment-variables-and-fields-for-client-unified-authentication).
#'
#' @inheritParams DBI::dbConnect
#' @param server A fully-qualified Synapse server name, e.g.
#'   `"<server-name>.sql.azuresynapse.net"` (for dedicated pools) or
#'   `"<server-name>-ondemand.sql.azuresynapse.net"` (for serverless pools)
#' @param database The name of the Synapse database to connect to.
#' @param driver The name of the Microsoft SQL Server ODBC driver, or `NULL` to
#'   use the default name.
#' @param uid,pwd A username and password to use for authentication. Or omit
#'   these to use Entra ID authentication instead, which is generally more
#'   secure.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Synapse
#'   cluster or SQL warehouse.
#'
#' @examples
#' \dontrun{
#' DBI::dbConnect(
#'   odbc::synapse(),
#'   httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
#' )
#'
#' # Use credentials from the viewer (when possible) in a Shiny app
#' # deployed to Posit Connect.
#' library(connectcreds)
#' server <- function(input, output, session) {
#'   conn <- DBI::dbConnect(
#'     odbc::synapse(),
#'     httpPath = "sql/protocolv1/o/4425955464597947/1026-023828-vn51jugj"
#'   )
#' }
#' }
#' @export
synapse <- function() {
  new("SynapseOdbcDriver")
}

#' @rdname synapse
#' @export
setClass("SynapseOdbcDriver", contains = "OdbcDriver")

#' @rdname synapse
#' @export
setMethod("dbConnect", "SynapseOdbcDriver",
  function(drv,
           # TODO: Can we use a Synapse workspace here somehow instead?
           # See: https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/connect-overview
           server,
           database,
           driver = NULL,
           uid = NULL,
           pwd = NULL,
           ...) {
    call <- caller_env()
    check_string(server, allow_empty = FALSE, call = call)
    check_string(database, allow_empty = FALSE, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)
    args <- synapse_args(
      server = server,
      database = database,
      driver = driver,
      uid = uid,
      pwd = pwd,
      ...,
      call = call
    )
    inject(dbConnect(odbc(), !!!args))
  }
)

synapse_args <- function(
  driver = NULL,
  uid = NULL,
  pwd = NULL,
  ...,
  call = current_env()
) {
  default_args <- list(
    driver = driver %||% synapse_default_driver(call = call),
    encrypt = "yes",
    port = 1433L
  )
  auth_args <- synapse_auth_args(uid = uid, pwd = pwd, call = call)
  utils::modifyList(c(default_args, auth_args), list(...))
}

# Returns a sensible driver name even if odbc.ini and odbcinst.ini do not
# contain an entry for the Synapse ODBC driver. For Linux and macOS we
# default to known shared library paths used by the official installers.
# On Windows we use the official driver name.
synapse_default_driver <- function(call = current_env()) {
  find_default_driver(
    synapse_default_driver_paths(),
    # FIXME
    fallbacks = c("Synapse", "Simba Spark ODBC Driver"),
    label = "SQL Server",
    call = call
  )
}

# FIXME
synapse_default_driver_paths <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    paths <- Sys.glob(c(
      "/opt/rstudio-drivers/spark/bin/lib/libsparkodbc_sb*.so",
      "/opt/simba/spark/lib/64/libsparkodbc_sb*.so"
    ))
  } else if (Sys.info()["sysname"] == "Darwin") {
    paths <- Sys.glob("/Library/simba/spark/lib/libsparkodbc_sb*.dylib")
  } else {
    paths <- character()
  }
  paths
}

synapse_auth_args <- function(host, uid = NULL, pwd = NULL, call = current_env()) {
  # Detect viewer-based credentials from Posit Connect.
  #
  # TODO: Is this actually the right scope?
  scope <- "https://database.windows.net/.default"
  if (is_installed("connectcreds")) {
    if (connectcreds::has_viewer_token(scope = scope)) {
      token <- connectcreds::connect_viewer_token(scope = scope)
      return(list(attributes = list("azure_token" = token$access_token)))
    }
  }

  if (!is.null(uid) && !is.null(pwd)) {
    return(list(uid = uid, pwd = pwd, authentication = "SqlPassword"))
  } else if (xor(is.null(uid), is.null(pwd))) {
    cli::cli_abort(
      c(
        "Both {.arg uid} and {.arg pwd} must be specified for username and \
        password authentication.",
        i = "Or leave both unset to use Entra ID authentication."
      ),
      call = call
    )
  }

  # Detect Azure service principals.
  client_id <- Sys.getenv("AZURE_CLIENT_ID")
  client_secret <- Sys.getenv("AZURE_CLIENT_SECRET")
  if (nchar(client_id) && nchar(client_secret)) {
    return(list(
      uid = client_id,
      pwd = client_secret,
      authentication = "ActiveDirectoryServicePrincipal"
    ))
  }

  # Masquerade as the Azure CLI for interactive authentication.
  client_id <- "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  if (is_interactive() && !is_hosted_session()) {
    check_installed("httr2", "for interactive Entra ID authentication")
    client <- httr2::oauth_client(
      client_id,
      token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
      secret = "",
      auth = "body",
      name = paste0("odbc-", client_id)
    )
    token <- httr2::oauth_token_cached(
      client,
      oauth_flow_auth_code,
      flow_params = list(
        auth_url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
        scope = paste(scope, "offline_access"),
        redirect_uri = "http://localhost:8400",
        auth_params = list(prompt = "select_account")
      )
    )
    return(list(attributes = list("azure_token" = token$access_token)))
  }

  cli::cli_abort(
    c(
      "No Entra ID credentials available.",
      "i" = "Supply {.arg uid} and {.arg pwd} to authenticate with a username \
             and password.",
      "i" = if (running_on_connect()) {
        "Or consider enabling Posit Connect's Synapse integration for
        viewer-based credentials. See {.url https://docs.posit.co/connect/user/oauth-integrations/#adding-oauth-integrations-to-deployed-content}
        for details."
      }
    ),
    call = call
  )
}
