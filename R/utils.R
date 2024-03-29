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
