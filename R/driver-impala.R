#' @include dbi-connection.R
NULL

# TODO: Revisit binary type (Impala)
#' @export
`odbcDataType.Impala` <- function(con, obj, ...) {
  switch_type(obj,
    factor = "STRING",
    datetime = "STRING",
    date = "VARCHAR(10)",
    integer = "INT",
    double = "DOUBLE",
    character = "STRING",
    logical = "BOOLEAN",
    list = "STRING",
    time = ,
    stop("Unsupported type", call. = FALSE)
  )
}
