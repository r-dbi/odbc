has_names <- function(x) {
  nms <- names(x)
  if (is.null(nms)) {
    rep(FALSE, length(x))
  } else {
    !(is.na(nms) | nms == "")
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

string_values <- function(x) {
  # TODO: Throw a condition object that can be caught for debugging purposes
  x <- tryCatch(x, error = function(x) "")
  unique(x[nzchar(x)])
}

# version of iconv that respects input Encoding, which bare iconv does not.
enc2iconv <- function(x, to, ...) {
  encodings <- Encoding(x)
  for (enc in unique(encodings)) {
    if (enc == to) {
      next
    }
    current <- enc == encodings
    if (enc == "unknown") {
      enc <- ""
    }
    x[current] <- iconv(x[current], from = enc, to = to, ...)
  }
  x
}

choices_rd <- function(x) {
  paste0(collapse = ", ", paste0("'", x, "'"))
}

lengths <- function(x) {
  vapply(x, length, integer(1))
}

# A 'size' must be an integer greater than 1, returned as a double so we have a larger range
parse_size <- function(x, arg = caller_arg(x), call = caller_env()) {
  check_number_whole(x, min = 1, arg = arg, call = call)
  as.numeric(x)
}

id_field <- function(id,
                     field = c("catalog", "schema", "table"),
                     error_call = caller_env()) {
  arg_match(field, error_call = error_call)

  if (length(id@name) == 1) {
    switch(field,
      catalog = NULL,
      schema = NULL,
      table = id@name[[1]],
    )
  } else if (length(id@name) == 2) {
    switch(field,
      catalog = NULL,
      schema = id@name[[1]],
      table = id@name[[2]],
    )
  } else if (length(id@name) == 3) {
    switch(field,
      catalog = id@name[[1]],
      schema = id@name[[2]],
      table = id@name[[3]],
    )
  } else {
    abort("Identifier must be length 1, 2, or 3.", call = error_call)
  }
}

isPatternValue <- function(val) {
  grepl("[%|_]", val)
}

# Per ODBC spec, "%" is synonymous with
# zero or more of any characters. "_" is
# any one character.  Here we convert
# a string with pattern value style wildcards
# to one that can be used in a regex search.
convertWildCards <- function(val) {
  val <- gsub("%", "(.*)", val)
  gsub("_", "(.)", val)
}

# Will return " AND key [= | LIKE] value"
# where "=" or "LIKE" is chosen depending
# on the the `exact` argument, and whether
# the `value` contains any wild card characters.
#
# Note, wild cards are not escaped in `value`
# as part of this call.
getSelector <- function(key, value, exact) {
  if (is.null(value)) {
    return("")
  }
  comp <- " = "
  if ((value == "%" || !exact) &&
    isPatternValue(value)) {
    comp <- " LIKE "
  }
  value <- paste0("'", value, "'")

  paste0(" AND ", key, comp, value)
}

# Will iterate over charsToEsc argument and for each:
# will escape any un-escaped occurance in `x`.
escapePattern <- function(x, charsToEsc = c("_"), escChar = "\\\\") {
  if (is.null(x) || inherits(x, "AsIs")) {
    return(x)
  }
  matchGroup <- paste(charsToEsc, collapse = "|")
  pattern <- paste0("([^", escChar, "])(", matchGroup, ")")
  replace <- paste0("\\1", escChar, "\\2")
  x <- gsub(pattern, replace, x)
  I(x)
}

is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

is_macos <- function() {
  identical(Sys.info()[["sysname"]], "Darwin")
}

compact <- function(x) x[!vapply(x, is.null, logical(1))]

set_odbcsysini <- function() {
  odbcsysini <- Sys.getenv("ODBCSYSINI")
  if (!identical(odbcsysini, "")) {
    return(invisible())
  }

  tryCatch(
    {
      path <- dirname(odbcListConfig()[["drivers"]])
      Sys.setenv(ODBCSYSINI = path)
    },
    error = function(err) NULL
  )

  invisible()
}

random_name <- function(prefix = "") {
  vals <- c(letters, LETTERS, 0:9)
  name <- paste0(sample(vals, 10, replace = TRUE), collapse = "")
  paste0(prefix, "odbc_", name)
}

# error handling ---------------------------------------------------------------
# `call` looks to the "user-called" function rather than the usual `caller_env(n)`.
# this function is called from C++, and parent.frame() (and thus caller_env())
# is unable to traverse across the Rcpp code to find the caller env; setting
# `call = caller_env(n)` with n of 0/1/2/3 gives no error context (#789).
rethrow_database_error <- function(msg, call = trace_back()$call[[1]]) {
  tryCatch(
    res <- parse_database_error(msg),
    error = function(e) cli::cli_abort(msg, call = call)
  )

  cli::cli_abort(
    c(
      "!" = "ODBC failed with error {res$cnd_context_code} from \\
             {.field {paste0(res$cnd_context_driver, collapse = '')}}.",
      set_database_error_names(res$cnd_body),
      "i" = "From {.file {res$cnd_context_nanodbc}}."
    ),
    class = "odbc_database_error",
    call = call
  )
}

parse_database_error <- function(msg) {
  # Split nanodbc's context, error code, and message returned from the database
  cnd_msg <- strsplit(msg, "\n", fixed = TRUE)[[1]]

  # Parse out nanodbc/nanodbc.cpp:<line#> and 5-char error code
  cnd_context <- strsplit(cnd_msg[1], ": ")[[1]]
  cnd_context_nanodbc <- cnd_context[1]
  cnd_context_code <- cnd_context[2]

  # In error returned from the database, find the square-bracketed context
  # on driver and driver manager
  cnd_context_driver <- gregexpr("(\\[.*?\\])", cnd_msg[-1])
  cnd_context_driver <- regmatches(cnd_msg[-1], cnd_context_driver)[[1]]

  # Remove the square-bracketed context from the database error
  cnd_body <- Reduce(
    function(p, x) gsub(p, "", x, fixed = TRUE),
    cnd_context_driver,
    cnd_msg[-1],
    right = TRUE
  )

  cnd_body <- contextualize_database_error(cnd_body)

  list(
    cnd_context_nanodbc = cnd_context_nanodbc,
    cnd_context_code = cnd_context_code,
    cnd_context_driver = cnd_context_driver,
    cnd_body = cnd_body
  )
}

contextualize_database_error <- function(cnd_body) {
  if (length(cnd_body) == 0 || !is_character(cnd_body)) {
    return(cnd_body)
  }

  if (any(grepl("Data source name not found", cnd_body))) {
    cnd_body <-
      c(
        cnd_body,
        "i" = "See {.help odbc::odbcListDataSources} to learn more."
      )
  }

  cnd_body
}

set_database_error_names <- function(cnd_body) {
  # Respect names from `contextualize_database_error()`, otherwise ensure
  # that the first is an "x" and the remainder are bulleted.
  if (length(cnd_body) == 0) {
    return(cnd_body)
  }

  if (is.null(names(cnd_body))) {
    return(
      set_names(cnd_body, nm = c("x", rep("*", length(cnd_body) - 1)))
    )
  }

  set_names(
    cnd_body,
    c(
      ifelse(names(cnd_body[1]) == "", "x", names(cnd_body[1])),
      ifelse(names(cnd_body[-1]) == "", "*", names(cnd_body[-1]))
    )
  )
}

# check helpers for common odbc arguments --------------------------------------
check_row.names <- function(row.names, call = caller_env()) {
  if (is.null(row.names) || is_scalar_logical(row.names) || is_string(row.names)) {
    return()
  }

  cli::cli_abort(
    "{.arg row.names} must be {.code NULL}, {.code TRUE}, {.code FALSE}, \\
     {.code NA}, or a single string, not {.obj_type_friendly {row.names}}.",
    call = call
  )
}

check_field.types <- function(field.types, call = caller_env()) {
  if (!(is_null(field.types) || (is_named(field.types)))) {
    cli::cli_abort(
      "{.arg field.types} must be {.code NULL} or a named vector of field \\
       types, not {.obj_type_friendly {field.types}}.",
      call = call
    )
  }
}

check_attributes <- function(attributes, call = caller_env()) {
  if (!all(has_names(attributes))) {
    cli::cli_abort("All elements of {.arg attributes} must be named.", call = call)
  }

  attributes_supported <- names(attributes) %in% SUPPORTED_CONNECTION_ATTRIBUTES
  if (!all(attributes_supported)) {
    cli::cli_abort(
      c("!" = "{.arg attributes} does not support the connection attribute{?s} \\
               {.val {names(attributes)[!attributes_supported]}}.",
        "i" = "Allowed connection attribute{?s} {?is/are} \\
               {.val {SUPPORTED_CONNECTION_ATTRIBUTES}}."),
      call = call
    )
  }
}

# apple + spark drive config (#651) --------------------------------------------
configure_spark <- function(call = caller_env()) {
  if (!is_macos()) {
    return(invisible())
  }

  unixodbc_install <- locate_install_unixodbc()
  if (length(unixodbc_install) == 0) {
    error_install_unixodbc(call)
  }

  spark_config <- locate_config_spark()
  if (length(spark_config) == 0) {
    abort(
      c(
        "Unable to locate the needed spark ODBC driver.",
        i = "Please install the needed driver from https://www.databricks.com/spark/odbc-drivers-download."
      ),
      call = call
    )
  }

  configure_unixodbc_spark(unixodbc_install[1], spark_config[1], call)
}

locate_install_unixodbc <- function() {
  libodbcinst <- c(
    system_safely("odbc_config --lib-prefix"),
    system_safely("pkg-config --variable=libdir odbc")
  )

  if (length(libodbcinst) > 0) {
    return(libodbcinst[1])
  }

  common_dirs <- c(
    "/usr/lib",
    "/usr/local",
    "/lib",
    "/usr/local/lib",
    "/opt/homebrew/lib",
    "/opt/homebrew/opt/unixodbc/lib"
  )

  list.files(
    common_dirs,
    pattern = libodbcinst_filename(),
    full.names = TRUE
  )
}

system_safely <- function(x) {
  tryCatch(
    {
      unixodbc_prefix <- system(x, intern = TRUE, ignore.stderr = TRUE)
      return(paste0(unixodbc_prefix, "/", libodbcinst_filename()))
    },
    error = function(e) {},
    warning = function(w) {}
  )
  character()
}

libodbcinst_filename <- function() {
  if (is_macos()) {
    "libodbcinst.dylib"
  } else {
    "libodbcinst.so"
  }
}

error_install_unixodbc <- function(call) {
  abort(
    c(
      "Unable to locate the unixODBC driver manager.",
      i = if (is_macos()) "Please install unixODBC using Homebrew with `brew install unixodbc`.",
      i = if (!is_macos()) "Please install unixODBC and retry."
    ),
    call = call
  )
}

# p. 44 https://downloads.datastax.com/odbc/2.6.5.1005/Simba%20Spark%20ODBC%20Install%20and%20Configuration%20Guide.pdf
locate_config_spark <- function() {
  spark_env <- Sys.getenv("SIMBASPARKINI")
  if (!identical(spark_env, "")) {
    return(spark_env)
  }

  common_dirs <- c(
    "/Library/simba/spark/lib",
    "/etc",
    getwd(),
    Sys.getenv("HOME")
  )

  list.files(
    common_dirs,
    pattern = "simba\\.sparkodbc\\.ini$",
    full.names = TRUE
  )
}

configure_unixodbc_spark <- function(unixodbc_install, spark_config, call) {
  # As shipped, the simba spark ini has an incomplete final line
  suppressWarnings(
    spark_lines <- readLines(spark_config)
  )

  spark_lines_new <- replace_or_append(
    lines = spark_lines,
    pattern = "^ODBCInstLib=",
    replacement = paste0("ODBCInstLib=", unixodbc_install)
  )

  spark_lines_new <- replace_or_append(
    lines = spark_lines_new,
    pattern = "^DriverManagerEncoding=",
    replacement = "DriverManagerEncoding=UTF-16"
  )

  write_spark_lines(spark_lines, spark_lines_new, spark_config, call)

  invisible()
}

write_spark_lines <- function(spark_lines, spark_lines_new, spark_config, call) {
  if (identical(spark_lines, spark_lines_new)) {
    return(invisible())
  }

  # see assertthat::is.writeable
  if (!is_writeable(spark_config)) {
    abort(
      c(
        paste0(
          "Detected needed changes to the driver configuration file at ",
          spark_config,
          ", but the file was not writeable."
        ),
        i = "Please make the changes outlined at https://solutions.posit.co/connections/db/databases/databricks/#troubleshooting-apple-macos-users."
      ),
      call = call
    )
  }

  writeLines(spark_lines_new, spark_config)
}

is_writeable <- function(path) {
  tryCatch(file.access(path, mode = 2)[[1]] == 0, error = function(e) FALSE)
}

# given a vector of lines in an ini file, look for a given key pattern.
# the `replacement` is the whole intended line, giving the "key=value" pair.
# if the key is found, replace that line with `replacement`.
# if the key isn't found, append a new line with `replacement`.
replace_or_append <- function(lines, pattern, replacement) {
  matching_lines_loc <- grepl(pattern, lines)
  matching_lines <- lines[matching_lines_loc]
  if (length(matching_lines) == 0) {
    lines <- c(lines, replacement)
  } else {
    lines[matching_lines_loc] <- replacement
  }
  lines
}
