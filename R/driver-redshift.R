#' @export
#' @rdname DBI-classes
setClass("Redshift", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Redshift", function(con, obj, ...) {
  switch_type(
    obj,
    factor = "VARCHAR(255)",
    datetime = "TIMESTAMP",
    date = "DATE",
    integer = "INTEGER",
    int64 = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "VARCHAR(255)",
    logical = "BOOLEAN",
    list = "VARCHAR(255)",
    time = ,
    binary = ,
    stop("Unsupported type", call. = FALSE)
  )
})

#' Helper for Connecting to Redshift via ODBC
#'
#' @description
#'
#' Connect to Redshift clusters via ODBC.
#'
#' In particular, the custom `dbConnect()` method for Redshift ODBC drivers
#' automatically determines whether IAM-based credentials are available, much
#' like other AWS SDKs and tools. This requires the \pkg{paws.common} package.
#'
#' @inheritParams DBI::dbConnect
#' @param clusterId The Redshift cluster identifier. Only one of `clusterId` or
#'   the more verbose `server` is required.
#' @param region The AWS region the Redshift cluster runs in. Ignored when
#'   `server` is provided. Defaults to the value of the environment variable
#'   `AWS_REGION`, then `AWS_REGION`, or uses `us-east-1` if both are unset.
#' @param database The name of the Redshift database to connect to.
#' @param dbUser The Redshift database account.
#' @param server The full hostname of the Redshift cluster.
#' @param driver The name of or path to a Redshift ODBC driver, or `NULL` to
#'   locate one automatically.
#' @param uid,pwd Disable IAM credentials and manually specify a username and
#'   password for authentication.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Redshift
#'   cluster or SQL warehouse.
#'
#' @examples
#' \dontrun{
#' # Connect to Redshift using IAM credentials.
#' DBI::dbConnect(
#'   odbc::redshift(),
#'   clusterId = "my-testing-cluster",
#'   database = "dev",
#'   dbUser = "me"
#' )
#' }
#' @export
redshift <- function() {
  new("RedshiftOdbcDriver")
}

#' @rdname redshift
#' @export
setClass("RedshiftOdbcDriver", contains = "OdbcDriver")

#' @rdname redshift
#' @export
setMethod(
  "dbConnect",
  "RedshiftOdbcDriver",
  function(
    drv,
    clusterId,
    server,
    database,
    region = NULL,
    driver = NULL,
    uid = NULL,
    pwd = NULL,
    dbUser = uid,
    ...
  ) {
    call <- caller_env()
    switch(
      check_exclusive(clusterId, server, .call = call),
      clusterId = check_string(clusterId, allow_empty = FALSE, call = call),
      server = check_string(server, allow_empty = FALSE, call = call)
    )
    region <- region %||% default_aws_region()
    check_string(region, allow_empty = FALSE, call = call)
    check_string(database, allow_empty = FALSE, call = call)
    check_string(driver, allow_null = TRUE, call = call)
    check_string(uid, allow_null = TRUE, call = call)
    check_string(pwd, allow_null = TRUE, call = call)
    args <- redshift_args(
      driver = driver,
      uid = uid,
      pwd = pwd,
      clusterId = if (!missing(clusterId)) clusterId,
      region = if (!missing(clusterId)) region,
      server = if (!missing(server)) server,
      database = database,
      dbUser = dbUser,
      ...
    )
    inject(dbConnect(odbc(), !!!args))
  }
)

redshift_args <- function(driver = NULL, uid = NULL, pwd = NULL, ...) {
  default_args <- list(
    driver = driver %||% redshift_default_driver(),
    port = 5439L,
    endpointUrl = getenv2("AWS_ENDPOINT_URL_REDSHIFT")
  )
  auth_args <- redshift_auth_args(uid = uid, pwd = pwd)
  utils::modifyList(c(default_args, auth_args), list(...))
}

redshift_default_driver <- function() {
  find_default_driver(
    redshift_default_driver_paths(),
    fallbacks = c("Redshift", "Amazon Redshift (x64)"),
    label = "Redshift",
    call = quote(DBI::dbConnect())
  )
}

redshift_default_driver_paths <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    c(
      "/opt/rstudio-drivers/redshift/bin/lib/libamazonredshiftodbc_sb64.so",
      "/opt/amazon/redshiftodbc/lib/64/libamazonredshiftodbc64.so",
      "/opt/amazon/redshiftodbcx64/librsodbc64.so"
    )
  } else if (Sys.info()["sysname"] == "Darwin") {
    "/opt/amazon/redshift/lib/amazonredshiftodbc.dylib"
  } else {
    character()
  }
}

redshift_auth_args <- function(uid = NULL, pwd = NULL) {
  if (!is.null(uid) && !is.null(pwd)) {
    return(list(uid = uid, pwd = pwd))
  }
  if (is.null(uid) && !is.null(pwd)) {
    cli::cli_abort(
      c(
        "Both {.arg uid} and {.arg pwd} must be specified for manual \
         authentication to Redshift.",
        i = "Or leave {.arg pwd} unset to use IAM credentials."
      ),
      call = quote(DBI::dbConnect())
    )
  }
  check_installed("paws.common", "to use IAM credentials for Redshift")
  try_fetch(
    {
      creds <- paws.common::locate_credentials()
      list(
        iam = 1L,
        accessKeyId = creds$access_key_id,
        secretAccessKey = creds$secret_access_key,
        sessionToken = creds$session_token
      )
    },
    error = function(cnd) {
      cli::cli_abort(
        c(
          "No IAM credentials found.",
          i = "Set {.arg uid} and {.arg pwd} for manual authentication to \
              Redshift."
        ),
        parent = cnd,
        call = quote(DBI::dbConnect())
      )
    }
  )
}

default_aws_region <- function() {
  # Check the preferred AWS_REGION environment variable but respect the ancient
  # AWS_DEFAULT_REGION one when set, too.
  getenv2("AWS_REGION", "AWS_DEFAULT_REGION", .unset = "us-east-1")
}
