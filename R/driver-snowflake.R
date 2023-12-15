#' @include dbi-connection.R
NULL

#' @export
`odbcDataType.Snowflake` <- function(con, obj, ...) {
  switch_type(
    obj,
    factor = "VARCHAR",
    datetime = "TIMESTAMP",
    date = "DATE",
    time = "TIME",
    binary = "BINARY",
    integer = "INTEGER",
    double = "FLOAT",
    character = "VARCHAR",
    logical = "BOOLEAN",
    list = "VARCHAR",
    stop("Unsupported type", call. = FALSE)
  )
}
