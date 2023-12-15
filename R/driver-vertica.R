#' @export
`odbcDataType.Vertica Database` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "VARCHAR",
    datetime = "TIMESTAMP",
    date = "DATE",
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "VARCHAR",
    logical = "BOOLEAN",
    list = "VARCHAR",
    time = "TIME",
    binary = "VARBINARY",
    stop("Unsupported type", call. = FALSE)
  )
}
