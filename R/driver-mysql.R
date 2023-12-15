
#' @export
`odbcDataType.MySQL` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "TEXT",
    datetime = "DATETIME",
    date = "DATE",
    time = "TIME",
    binary = "BLOB",
    integer = "INTEGER",
    double = "DOUBLE",
    character = "TEXT",
    logical = "TINYINT",
    list = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}
