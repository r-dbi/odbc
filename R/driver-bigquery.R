#' @include dbi-connection.R
NULL

#' @export
`odbcDataType.BigQuery` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "STRING",
    datetime = "TIMESTAMP",
    time = "TIME",
    date = "DATE",
    binary = "BYTES",
    integer = "INT64",
    int64 = "INT64",
    double = "FLOAT64",
    character = "STRING",
    logical = "BOOL",
    stop("Unsupported type", call. = FALSE)
  )
}
