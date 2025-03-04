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
    error = function(e) cli::cli_abort("{msg}", call = call)
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

  cnd_body <- escape_curly_brackets(cnd_body)

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

# Escape curly brackets before formatting with cli (#859). Do so only to
# unnamed elements so that formatting is preserved for context
# added with `contextualize_database_error()`.
escape_curly_brackets <- function(cnd_body) {
  if (is.null(names(cnd_body))) {
    return(gsub("\\{", "{{", gsub("\\}", "}}", cnd_body)))
  }

  unnamed <- names(cnd_body) == ""
  cnd_body[unnamed] <- gsub("\\{", "{{", gsub("\\}", "}}", cnd_body[unnamed]))
  cnd_body
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
# Method will attempt to:
# 1. Locate an installation of unixodbc / error out otherwise.
# 2. Verify the driver_config argument.  Expect this to be a list with
#    two fields:
#    * path Vector of viable driver paths ( only first one is used )
#    * url A location where the user can downlaod the driver from.
#    See spark_simba_config, for example.  Its return value is used as
#    the value for this argument.
# 3. Inspect the config for some settings that can impact how our package
#    performs.
# 4. If action == "modify" then we attempt to modify the config in-situ.
# 5. Otherwise we throw a warning asking the user to revise.
configure_simba <- function(driver_config,
                            action = "modify", call = caller_env()) {
  if (!is_macos()) {
    return(invisible())
  }
  if (!is.null(getOption("odbc.no_config_override"))) {
    return(invisible())
  }

  unixodbc_install <- locate_install_unixodbc()
  if (length(unixodbc_install) == 0) {
    error_install_unixodbc(call)
  }

  simba_config <- driver_config$path
  if (length(simba_config) == 0) {
    func <- cli::cli_warn
    if (action == "modify") {
      fun <- cli::cli_abort
    }
    func(
      c(i = "Please install the needed driver from {driver_config$url}"),
      call = call
    )
  }
  configure_unixodbc_simba(unixodbc_install[1], simba_config[1], action, call)
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
    "/usr/lib/x86_64-linux-gnu",
    "/opt/homebrew/lib",
    "/opt/homebrew/etc",
    "/opt/homebrew/opt/unixodbc/lib",
    "/opt/R/arm64/lib",
    "/opt/R/x86_64/lib"
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
      candidates <- list.files(unixodbc_prefix,
        pattern = libodbcinst_filename(), full.names = TRUE)
      if (!length(candidates)) {
        stop("Unable to locate unixodbc using odbc_config")
      }
      return(candidates[1])
    },
    error = function(e) {},
    warning = function(w) {}
  )
  character()
}

# Returns a pattern to be used with
# list.files( ..., pattern = ... ).
libodbcinst_filename <- function() {
  if (is_macos()) {
    "libodbcinst.dylib|libodbcinst.a"
  } else {
    "libodbcinst.so|libodbcinst.a"
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

configure_unixodbc_simba <- function(unixodbc_install, simba_config, action, call) {

  # As shipped, the simba spark ini has an incomplete final line
  suppressWarnings(
    simba_lines <- readLines(simba_config)
  )
  res <- replace_or_append(
    lines = simba_lines,
    key_pattern = "^ODBCInstLib=",
    accepted_value = unixodbc_install,
    replacement = paste0("ODBCInstLib=", unixodbc_install)
  )
  warnings <- character()
  if (action != "modify" && res$modified) {
     warnings <- c(warnings, c("*" = "Please consider revising the {.arg ODBCInstLib}
       field in {.file {simba_config}} and setting its value to {.val {unixodbc_install}}"))
  }
  simba_lines_new <- res$new_lines
  res <- replace_or_append(
    lines = simba_lines_new,
    key_pattern = "^DriverManagerEncoding=",
    accepted_value = "UTF-16|utf-16",
    replacement = "DriverManagerEncoding=UTF-16"
  )
  if (action != "modify" && res$modified) {
     warnings <- c(warnings, c("*" = "Please consider revising the
       {.arg DriverManagerEncoding} field in {.file {simba_config}} and setting its
       value to {.val UTF-16}."))
  }
  if (length(warnings)) {
    cli::cli_warn(c(
      c(i = "Detected potentially unsafe driver settings:"),
      warnings
    ))
  }
  simba_lines_new <- res$new_lines

  if (action == "modify") {
    write_simba_lines(simba_lines, simba_lines_new, simba_config, call)
  }

  invisible()
}

write_simba_lines <- function(spark_lines, spark_lines_new, spark_config, call) {
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

# Interpret the argument as an `ODBC` driver
# and attempt to infer the directory housing it.
# It will return an empty character vector if unable to.
driver_dir <- function(driver) {
  # driver argument could be an outright path, or a name
  # of a driver specified in odbcinst.ini  Try to discern
  driver_spec <- subset(odbcListDrivers(), name == driver)
  if (nrow(driver_spec)) {
    driver_path <- subset(driver_spec, attribute == "Driver")$value
  } else {
    driver_path <- driver
  }

  ret <- dirname(driver_path)
  if (ret == ".") {
    ret <- character()
  }
  return(ret)
}

is_writeable <- function(path) {
  tryCatch(file.access(path, mode = 2)[[1]] == 0, error = function(e) FALSE)
}

# Given a vector of lines in an ini file, look for a given key pattern.
# If found:
# - No action if the `accepted_value` argument is found on line.
# - Replace otherwise.
# If not found: append.
# The `replacement` is the whole intended line, giving the desired
# "key=value" pair.
# @return a list with two elements:
# - new_lines: Potentially modified lines
# - modified: Whether method modified lines, where modified means
# both changed or appended.
replace_or_append <- function(lines, key_pattern, accepted_value, replacement) {
  matching_lines_loc <- grepl(key_pattern, lines)
  matching_lines <- lines[matching_lines_loc]
  found_ok <- length(matching_lines) != 0 &&
    any(grepl(accepted_value, lines[matching_lines_loc]))
  if (length(matching_lines) == 0) {
    lines <- c(lines, replacement)
  } else if (!found_ok) {
    lines[matching_lines_loc] <- replacement
  }
  return(list(new_lines = lines, modified = !found_ok))
}

running_on_connect <- function() {
  Sys.getenv("RSTUDIO_PRODUCT") == "CONNECT"
}

# Like Sys.getenv(), but checks passed keys in order and allows for non-string
# defaults.
getenv2 <- function(..., .unset = NULL) {
  x <- as.character(list(...))
  env <- Sys.getenv(x, NA_character_)
  if (all(is.na(env))) {
    return(.unset)
  }
  val <- env[!is.na(env)][1]
  unname(val)
}

find_default_driver <- function(paths, fallbacks, label, call = caller_env()) {
  paths <- paths[file.exists(paths)]
  if (length(paths) > 0) {
    return(paths[1])
  }
  fallbacks <- intersect(fallbacks, odbcListDrivers()$name)
  if (length(fallbacks) > 0) {
    return(fallbacks[1])
  }
  cli::cli_abort(
    c(
      "Failed to automatically find the {label} ODBC driver.",
      i = "Set {.arg driver} to known driver name or path."
    ),
    call = call
  )
}
