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
  paste0(collapse = ", ", paste0("\\sQuote{", x, "}"))
}

lengths <- function(x) {
  vapply(x, length, integer(1))
}
