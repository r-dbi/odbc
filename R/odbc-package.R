#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom bit64 integer64
#' @importFrom blob blob
#' @importFrom hms hms
#' @importFrom lifecycle deprecated
#' @importFrom Rcpp sourceCpp
# this one is just for the purposes of quieting the R CMD check NOTE,
# which doesn't seem to recognize our vctrs use in setMethod
#' @importFrom vctrs list_of
#' @useDynLib odbc, .registration = TRUE
## usethis namespace: end
NULL

utils::globalVariables(c("attribute", "name"))
