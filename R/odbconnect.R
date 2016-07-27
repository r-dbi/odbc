#' @useDynLib odbconnect
#' @importFrom Rcpp sourceCpp
NULL

print.externalptr <- function(x) {
  cat(format_connection(x), "\n")
}
