#' @export
#' @rdname DBI-classes
setClass("Redshift", contains = "OdbcConnection")

#' @export
#' @rdname odbcDataType
#' @usage NULL
setMethod("odbcDataType", "Redshift",
  function(con, obj, ...) {
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
  }
)

#' Helper for Connecting to Redshift via ODBC
#'
#' @description
#'
#' Connect to Redshift clusters via ODBC.
#'
#' In particular, the custom `dbConnect()` method for Redshift ODBC drivers
#' automatically determines whether IAM-based credentials are available, much
#' like other AWS SDKs and tools.
#'
#' @inheritParams DBI::dbConnect
#' @param clusterId The Redshift cluster identifier. Only one of `clusterId` or
#'   the more verbose `server` is required.
#' @param region The AWS region the Redshift cluster runs in. Ignored when
#'   `server` is provided.
#' @param server The full hostname of the Redshift cluster.
#' @param driver The name of or path to a Redshift ODBC driver, or `NULL` to
#'   locate one automatically.
#' @param uid,pwd Manually specify a username and password for authentication.
#'   Specifying these options will disable automated credential discovery.
#' @param ... Further arguments passed on to [`dbConnect()`].
#'
#' @returns An `OdbcConnection` object with an active connection to a Redshift
#'   cluster or SQL warehouse.
#'
#' @examples
#' \dontrun{
#' # Connect to Redshift using ambient IAM credentials.
#' DBI::dbConnect(
#'   odbc::redshift(),
#'   clusterId = "my-testing-cluster",
#'   database = "dev"
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
setMethod("dbConnect", "RedshiftOdbcDriver",
  function(drv,
           clusterId,
           region = default_aws_region(),
           server,
           database,
           driver = NULL,
           uid = NULL,
           pwd = NULL,
           ...) {
    call <- caller_env()
    switch(
      check_exclusive(clusterId, server, .call = call),
      clusterId = check_string(clusterId, allow_empty = FALSE, call = call),
      server = check_string(server, allow_empty = FALSE, call = call)
    )
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
      ...
    )
    inject(dbConnect(odbc(), !!!args))
  }
)

redshift_args <- function(driver = NULL,
                          uid = NULL,
                          pwd = NULL,
                          ...) {
  default_args <- list(
    driver = driver %||% redshift_default_driver(),
    port = 5439L,
    endpointUrl = getenv2("AWS_ENDPOINT_URL_REDSHIFT", "AWS_ENDPOINT_URL"),
    stsEndpointUrl = getenv2("AWS_ENDPOINT_URL_STS")
  )
  auth_args <- redshift_auth_args(uid = uid, pwd = pwd)
  utils::modifyList(c(default_args, auth_args), list(...))
}

redshift_default_driver <- function() {
  find_default_driver(
    redshift_default_driver_paths(),
    fallbacks = c("Redshift", "Amazon Redshift ODBC Driver (x64)"),
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
  } else if (is.null(uid) && !is.null(pwd)) {
    cli::cli_abort(
      c(
        "Both {.arg uid} and {.arg pwd} must be specified for manual \
         authentication.",
        i = "Or leave {.arg pwd} unset to use IAM credentials."
      ),
      call = quote(DBI::dbConnect())
    )
  }

  # The precedence here follows the conventions of other AWS SDKs and the CLI.
  # See e.g. https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html#configuring-credentials
  #
  # The notable exception here is that the driver doesn't support AWS config
  # files -- though it *does* support shared credential files -- so we ignore
  # those for now.

  access_key_id <- getenv2("AWS_ACCESS_KEY_ID")
  if (!is.null(access_key_id)) {
    return(list(
      iam = 1L,
      accessKeyId = access_key_id,
      secretAccessKey = getenv2("AWS_SECRET_ACCESS_KEY"),
      sessionToken = getenv2("AWS_SESSION_TOKEN")
    ))
  }

  # Note: requires version 1.5.9 (November 2023).
  token_file <- getenv2("AWS_WEB_IDENTITY_TOKEN_FILE")
  if (!is.null(token_file)) {
    if (!file.exists(token_file)) {
      cli::cli_abort(
        c(
          "{.env AWS_WEB_IDENTITY_TOKEN_FILE} is set, but the file does not exist.",
          i = "Your IAM credentials may be misconfigured."
        ),
        call = quote(DBI::dbConnect())
      )
    }
    token <- readLines(token_file, warn = FALSE, encoding = "UTF-8")
    return(list(
      iam = 1L,
      plugin_name = "JwtIamAuthPlugin",
      role_arn = getenv2("AWS_ROLE_ARN"),
      role_session_name = getenv2("AWS_ROLE_SESSION_NAME"),
      web_identity_token = token
    ))
  }

  profile <- getenv2("AWS_PROFILE")
  if (!is.null(profile)) {
    return(list(iam = 1L, profile = profile))
  }

  # Default to the instance profile.
  list(iam = 1L, instanceProfile = 1L)
}

default_aws_region <- function() {
  # Check the preferred AWS_REGION environment variable but respect the ancient
  # AWS_DEFAULT_REGION one when set, too.
  getenv2("AWS_REGION", "AWS_DEFAULT_REGION", .unset = "us-east-1")
}
