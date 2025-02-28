#' @aliases NULL
#' @aliases odbc-package
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom bit64 integer64
#' @importFrom blob blob
#' @importFrom hms hms
#' @importFrom lifecycle deprecated
#' @importFrom Rcpp sourceCpp
#' @useDynLib odbc, .registration = TRUE
## usethis namespace: end
NULL

utils::globalVariables(c("attribute", "name", "simba_config_dirs"))
