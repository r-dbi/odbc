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
parse_size <- function(x) {
  nme <- substitute(x) %||% "NULL"

  if (rlang::is_scalar_integerish(x) && !is.na(x) && !is.infinite(x) && x > 0) {
    return(as.numeric(x))
  }

  stop(
    sprintf("`%s` is not a valid size:\n  Must be a positive integer.", as.character(nme)),
    call. = FALSE
  )
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

check_n <- function(n) {
  if (length(n) != 1) stop("`n` must be scalar", call. = FALSE)
  if (n < -1) stop("`n` must be nonnegative or -1", call. = FALSE)
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stop("`n` must be a whole number", call. = FALSE)
  n
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
      path <- dirname(odbcListConfig()$drivers)
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

# apple + spark drive config (#651) --------------------------------------------
configure_spark <- function(call = caller_env()) {
  if (!is_macos()) {
    return(invisible())
  }

  unixodbc_install <- locate_install_unixodbc()
  if (length(unixodbc_install) == 0) {
    abort(
      c(
        "Unable to locate the unixODBC driver manager.",
        i = "Please install unixODBC using Homebrew with `brew install unixodbc`."
      ),
      call = call
    )
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

  configure_unixodbc_spark(unixodbc_install[1], spark_config[1])
}

locate_install_unixodbc <- function() {
  tryCatch(
    {
      unixodbc_prefix <- system("odbc_config --lib-prefix", intern = TRUE)
      return(paste0(unixodbc_prefix, "/libodbcinst.dylib"))
    },
    error = function(e) {}
  )

  common_dirs <- c(
    "/usr/local/lib",
    "/opt/homebrew/lib",
    "/opt/homebrew/opt/unixodbc/lib"
  )

  list.files(
    common_dirs,
    pattern = "libodbcinst\\.dylib$",
    full.names = TRUE
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

configure_unixodbc_spark <- function(unixodbc_install, spark_config) {
  # As shipped, the simba spark ini has an incomplete final line
  suppressWarnings(
    spark_lines <- readLines(spark_config)
  )

  odbcinstlib_lines <- grepl("^ODBCInstLib=", spark_lines)
  odbcinstlib <- spark_lines[odbcinstlib_lines]
  odbcinstlib_config <- paste0("ODBCInstLib=", unixodbc_install)
  if (identical(odbcinstlib, character(0))) {
    spark_lines <- c(spark_lines, odbcinstlib_config)
  } else {
    spark_lines[odbcinstlib_lines] <- odbcinstlib_config
  }

  manager_encoding_lines <- grepl("^DriverManagerEncoding=", spark_lines)
  manager_encoding <- spark_lines[manager_encoding_lines]
  manager_encoding_config <- "DriverManagerEncoding=UTF-16"
  if (identical(manager_encoding, character(0))) {
    spark_lines <- c(spark_lines, manager_encoding_config)
  } else {
    spark_lines[manager_encoding_lines] <- manager_encoding_config
  }

  writeLines(spark_lines, spark_config)

  invisible()
}
