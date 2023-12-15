#' @export
`odbcDataType.Redshift` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "VARCHAR(255)",
    datetime = "TIMESTAMP",
    date = "DATE",
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "VARCHAR(255)",
    logical = "BOOLEAN",
    list = "VARCHAR(255)",
    time = ,
    binary = ,
    stop("Unsupported type", call. = FALSE)
  )
}
