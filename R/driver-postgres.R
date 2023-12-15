
#' @export
`odbcDataType.PostgreSQL` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "TEXT",
    datetime = "TIMESTAMP",
    date = "DATE",
    time = "TIME",
    binary = "bytea",
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}
