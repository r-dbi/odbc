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
  unique(x[nzchar(x)])
}
